@preconcurrency import HealthKit
import Foundation
@testable import PhoneWorkout

// MARK: - FakePhoneHealthStore

// @unchecked Sendable: all mutation from @MainActor test suite.
final class FakePhoneHealthStore: PhoneHealthStoreProtocol, @unchecked Sendable {

    private(set) var authorizationCallCount = 0
    private(set) var handlerSetCount = 0
    private(set) var startWatchAppCallCount = 0

    var authorizationError: Error?
    var startWatchAppError: Error?

    /// The most recently registered mirroring handler.
    private(set) var mirroringHandler: (@Sendable (any MirroredSessionProtocol) -> Void)?

    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws {
        authorizationCallCount += 1
        if let e = authorizationError { throw e }
    }

    @MainActor func setMirroringHandler(_ handler: (@Sendable (any MirroredSessionProtocol) -> Void)?) {
        handlerSetCount += 1
        mirroringHandler = handler
    }

    func startWatchApp(toHandle configuration: HKWorkoutConfiguration) async throws {
        startWatchAppCallCount += 1
        if let e = startWatchAppError { throw e }
    }
}

// MARK: - FakeMirroredSession

// @unchecked Sendable: all mutation from @MainActor test suite.
final class FakeMirroredSession: MirroredSessionProtocol, @unchecked Sendable {

    var state: HKWorkoutSessionState
    var startDate: Date?
    private(set) var stopActivityCallCount = 0
    private(set) var lastStopDate: Date?

    private weak var observer: (any MirroredSessionObserver)?

    init(state: HKWorkoutSessionState = .notStarted, startDate: Date? = nil) {
        self.state = state
        self.startDate = startDate
    }

    @MainActor func setObserver(_ observer: (any MirroredSessionObserver)?) {
        self.observer = observer
    }

    func stopActivity(with date: Date) {
        stopActivityCallCount += 1
        lastStopDate = date
    }

    // MARK: - Simulation helpers

    @MainActor func simulateStateChange(
        to toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState = .notStarted,
        date: Date = .now
    ) {
        observer?.mirroredSessionDidChangeState(to: toState, from: fromState, date: date)
    }

    @MainActor func simulateFail(error: Error) {
        observer?.mirroredSessionDidFail(error: error)
    }

    @MainActor func simulateDataReceived(_ data: [Data] = []) {
        observer?.mirroredSessionDidReceiveData(data)
    }
}
