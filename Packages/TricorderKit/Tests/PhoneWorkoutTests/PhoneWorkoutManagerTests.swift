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

    // MARK: - Stop

    @Test("stopWorkout on idle does not crash")
    func stopWorkoutOnIdleNoCrash() {
        let (sut, _) = makeSUT()
        sut.stopWorkout()
    }
}
