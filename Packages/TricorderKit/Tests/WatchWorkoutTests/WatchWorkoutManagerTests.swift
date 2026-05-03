import Testing
@preconcurrency import HealthKit
import Foundation
@testable import WatchWorkout
import WorkoutCore

private enum StubError: Error, Equatable { case stub }

@Suite("WatchWorkoutManager")
@MainActor
struct WatchWorkoutManagerTests {

    // MARK: - Helpers

    private func makeSUT() -> (sut: WatchWorkoutManager, store: FakeHealthStore) {
        let store = FakeHealthStore()
        return (WatchWorkoutManager(store: store), store)
    }

    /// Drains a pending Task { await ... } submitted on @MainActor.
    /// Both that task and this one are serial on the MainActor executor,
    /// so awaiting this guarantees the prior task has completed.
    private func drainMainActor() async {
        await Task { @MainActor in }.value
    }

    // MARK: - Authorization

    @Test("requestAuthorization succeeds: no throw, state unchanged")
    func authorizationSuccess() async throws {
        let (sut, store) = makeSUT()

        try await sut.requestAuthorization()

        #expect(store.authorizationCallCount == 1)
        #expect(sut.state == .idle)
    }

    @Test("requestAuthorization propagates store error")
    func authorizationFailure() async {
        let (sut, store) = makeSUT()
        store.authorizationError = StubError.stub

        await #expect(throws: StubError.stub) {
            try await sut.requestAuthorization()
        }
        #expect(sut.state == .idle)
    }

    @Test("requestAuthorization sends correct HealthKit types")
    func authorizationRequestsCorrectTypes() async throws {
        let (sut, store) = makeSUT()

        try await sut.requestAuthorization()

        let toShare = try #require(store.lastToShare)
        let read = try #require(store.lastRead)
        #expect(toShare.contains(.workoutType()))
        #expect(read.contains(.workoutType()))
        #expect(read.contains(HKQuantityType(.heartRate)))
    }

    // MARK: - Start

    @Test("startWorkout wires session, calls prepare and startActivity")
    func startWorkoutWiresSession() async throws {
        let (sut, store) = makeSUT()
        let session = store.fakeSession

        try await sut.startWorkout()

        #expect(session.prepareCallCount == 1)
        #expect(session.mirroringCallCount == 1)
        #expect(session.startActivityDates.count == 1)
        // beginCollection fires on .running — not yet called here
        #expect(session.fakeBuilder.beginCollectionDates.isEmpty)
    }

    @Test("running transition: state .active, beginCollection called")
    func runningTransitionStartsCollection() async throws {
        let (sut, store) = makeSUT()
        let session = store.fakeSession
        let startDate = Date(timeIntervalSince1970: 1_000)

        try await sut.startWorkout()
        session.simulateStateChange(to: .running, date: startDate)
        await drainMainActor()  // drain Task { await beginCollection }

        #expect(sut.state == .active(startDate: startDate))
        #expect(session.fakeBuilder.beginCollectionDates == [startDate])
        #expect(session.fakeBuilder.startDate == startDate)
    }

    @Test("startWorkout with active session: ignores, no new session created")
    func startWorkoutWithActiveSessionIgnores() async throws {
        let (sut, store) = makeSUT()
        let session = store.fakeSession

        try await sut.startWorkout()
        session.simulateStateChange(to: .running)

        try await sut.startWorkout()

        #expect(session.mirroringCallCount == 1, "must not remirror")
        #expect(session.startActivityDates.count == 1, "must not call startActivity again")
    }

    @Test("startWorkout propagates makeWorkoutSession error")
    func startWorkoutPropagatesSessionError() async {
        let (sut, store) = makeSUT()
        store.makeSessionError = StubError.stub

        await #expect(throws: StubError.stub) {
            try await sut.startWorkout()
        }
        #expect(sut.state == .idle)
    }

    @Test("startWorkout propagates mirroring error")
    func startWorkoutPropagatesMirroringError() async {
        let (sut, store) = makeSUT()
        store.fakeSession.mirroringError = StubError.stub

        await #expect(throws: StubError.stub) {
            try await sut.startWorkout()
        }
    }

    // MARK: - Stop

    @Test("stopWorkout calls stopActivity on session")
    func stopWorkoutCallsStopActivity() async throws {
        let (sut, store) = makeSUT()
        let session = store.fakeSession

        try await sut.startWorkout()
        session.simulateStateChange(to: .running)
        sut.stopWorkout()

        #expect(session.stopActivityDates.count == 1)
    }

    @Test("stopWorkout on idle state does not crash")
    func stopWorkoutOnIdleNoCrash() {
        let (sut, _) = makeSUT()
        sut.stopWorkout()  // optional chain on nil session — must not crash
    }

    // MARK: - State transitions

    @Test("stopped transition: state .idle, session.end() called")
    func stoppedTransitionEndsSession() async throws {
        let (sut, store) = makeSUT()
        let session = store.fakeSession

        try await sut.startWorkout()
        session.simulateStateChange(to: .running)
        session.simulateStateChange(to: .stopped)

        #expect(sut.state == .idle)
        #expect(session.endCallCount == 1)
    }

    @Test("ended transition: endCollection + finishWorkout called, session cleared")
    func endedTransitionFinalizesWorkout() async throws {
        let (sut, store) = makeSUT()
        let session = store.fakeSession
        let builder = session.fakeBuilder
        let endDate = Date(timeIntervalSince1970: 2_000)

        try await sut.startWorkout()
        session.simulateStateChange(to: .running)
        await drainMainActor()  // drain beginCollection so startDate is set before .ended fires

        session.simulateStateChange(to: .ended, date: endDate)
        await drainMainActor()  // drain finalizeWorkout

        #expect(builder.endCollectionDates == [endDate])
        #expect(builder.finishWorkoutCallCount == 1)

        // Session ref cleared: fresh startWorkout goes through full setup again.
        try await sut.startWorkout()
        #expect(session.startActivityDates.count == 2)
    }

    @Test("ended transition with no startDate: skips endCollection and finishWorkout")
    func endedWithNoStartDateSkipsFinalization() async throws {
        let (sut, store) = makeSUT()
        let session = store.fakeSession
        let builder = session.fakeBuilder
        // Skip .running — beginCollection never fires, startDate stays nil.

        try await sut.startWorkout()
        session.simulateStateChange(to: .ended, date: .now)
        await drainMainActor()

        #expect(builder.endCollectionDates.isEmpty)
        #expect(builder.finishWorkoutCallCount == 0)
    }

    @Test("sessionDidFail resets to idle and clears references")
    func sessionFailureClearsState() async throws {
        let (sut, store) = makeSUT()
        let session = store.fakeSession

        try await sut.startWorkout()
        session.simulateStateChange(to: .running)
        #expect(sut.state != .idle)

        session.simulateFailure(error: StubError.stub)

        #expect(sut.state == .idle)
        // Session ref cleared: startWorkout no longer hits the guard branch.
        try await sut.startWorkout()
        #expect(session.startActivityDates.count == 2)
    }

    // MARK: - Finalization error resilience

    @Test("endCollection error in finalize: session still cleared")
    func endCollectionErrorStillClears() async throws {
        let (sut, store) = makeSUT()
        let session = store.fakeSession
        session.fakeBuilder.endCollectionError = StubError.stub

        try await sut.startWorkout()
        session.simulateStateChange(to: .running)
        await drainMainActor()
        session.simulateStateChange(to: .ended, date: .now)
        await drainMainActor()

        try await sut.startWorkout()
        #expect(session.startActivityDates.count == 2)
    }

    @Test("finishWorkout error in finalize: session still cleared")
    func finishWorkoutErrorStillClears() async throws {
        let (sut, store) = makeSUT()
        let session = store.fakeSession
        session.fakeBuilder.finishWorkoutError = StubError.stub

        try await sut.startWorkout()
        session.simulateStateChange(to: .running)
        await drainMainActor()
        session.simulateStateChange(to: .ended, date: .now)
        await drainMainActor()

        try await sut.startWorkout()
        #expect(session.startActivityDates.count == 2)
    }
}
