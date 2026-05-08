import Testing
@preconcurrency import HealthKit
import Foundation
@testable import PhoneWorkout
import WorkoutCore

private enum StubError: Error, Equatable { case stub }

@Suite("PhoneWorkoutManager")
@MainActor
struct PhoneWorkoutManagerTests {

    // MARK: - Helpers

    private func makeSUT() -> (sut: PhoneWorkoutManager, store: FakePhoneHealthStore) {
        let store = FakePhoneHealthStore()
        return (PhoneWorkoutManager(store: store), store)
    }

    /// Delivers a session through the mirroring handler and waits for attach to run.
    private func deliver(
        _ session: FakeMirroredSession,
        via store: FakePhoneHealthStore
    ) async {
        store.mirroringHandler?(session)
        await Task.yield()
    }

    // MARK: - Mirroring handler registration

    @Test("init registers mirroring handler once")
    func initRegistersHandler() {
        let (_, store) = makeSUT()
        #expect(store.handlerSetCount == 1)
    }

    @Test("requestAuthorization re-registers handler after success")
    func authorizationReRegistersHandler() async throws {
        let (sut, store) = makeSUT()
        let countAfterInit = store.handlerSetCount

        try await sut.requestAuthorization()

        #expect(store.handlerSetCount == countAfterInit + 1)
    }

    @Test("requestAuthorization does not re-register handler on failure")
    func authorizationFailureSkipsReRegistration() async {
        let (sut, store) = makeSUT()
        store.authorizationError = StubError.stub
        let countAfterInit = store.handlerSetCount

        try? await sut.requestAuthorization()

        #expect(store.handlerSetCount == countAfterInit)
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

    // MARK: - Attach

    @Test("stale ended session is ignored")
    func staleEndedSessionIgnored() async {
        let (sut, store) = makeSUT()
        let session = FakeMirroredSession(state: .ended)

        await deliver(session, via: store)

        #expect(sut.state == .idle)
    }

    @Test("stale stopped session is ignored")
    func staleStoppedSessionIgnored() async {
        let (sut, store) = makeSUT()
        let session = FakeMirroredSession(state: .stopped)

        await deliver(session, via: store)

        #expect(sut.state == .idle)
    }

    @Test("already-running session sets active state on attach")
    func alreadyRunningSessionActivatesOnAttach() async {
        let (sut, store) = makeSUT()
        let startDate = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let session = FakeMirroredSession(state: .running, startDate: startDate)

        await deliver(session, via: store)

        #expect(sut.state == .active(startDate: startDate))
    }

    @Test("non-running session does not set active state on attach")
    func notYetRunningSessionStaysIdle() async {
        let (sut, store) = makeSUT()
        let session = FakeMirroredSession(state: .notStarted)

        await deliver(session, via: store)

        #expect(sut.state == .idle)
    }

    // MARK: - State machine

    @Test("state change to running → active")
    func stateChangeToRunning() async {
        let (sut, store) = makeSUT()
        let startDate = Date(timeIntervalSinceReferenceDate: 2_000_000)
        let session = FakeMirroredSession(state: .notStarted)

        await deliver(session, via: store)
        session.simulateStateChange(to: .running, date: startDate)

        #expect(sut.state == .active(startDate: startDate))
    }

    @Test("state change to stopped → idle, handler re-registered")
    func stateChangeToStopped() async {
        let (sut, store) = makeSUT()
        let session = FakeMirroredSession(state: .running, startDate: .now)

        await deliver(session, via: store)
        let countBeforeStop = store.handlerSetCount
        session.simulateStateChange(to: .stopped, from: .running)

        #expect(sut.state == .idle)
        #expect(store.handlerSetCount == countBeforeStop + 1)
    }

    @Test("session failure → idle")
    func sessionFailureSetsIdle() async {
        let (sut, store) = makeSUT()
        let session = FakeMirroredSession(state: .running, startDate: .now)

        await deliver(session, via: store)
        session.simulateFail(error: StubError.stub)

        #expect(sut.state == .idle)
    }

    // MARK: - Stop

    @Test("stopWorkout on idle does not crash")
    func stopWorkoutOnIdleNoCrash() {
        let (sut, _) = makeSUT()
        sut.stopWorkout()
    }

    @Test("stopWorkout calls stopActivity on mirrored session")
    func stopWorkoutCallsStopActivity() async {
        let (sut, store) = makeSUT()
        let session = FakeMirroredSession(state: .running, startDate: .now)

        await deliver(session, via: store)
        sut.stopWorkout()

        #expect(session.stopActivityCallCount == 1)
    }
}
