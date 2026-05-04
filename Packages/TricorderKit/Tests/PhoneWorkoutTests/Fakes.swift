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
    private(set) var mirroringHandler: (@Sendable (HKWorkoutSession) -> Void)?

    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws {
        authorizationCallCount += 1
        if let e = authorizationError { throw e }
    }

    @MainActor func setMirroringHandler(_ handler: (@Sendable (HKWorkoutSession) -> Void)?) {
        handlerSetCount += 1
        mirroringHandler = handler
    }

    func startWatchApp(toHandle configuration: HKWorkoutConfiguration) async throws {
        startWatchAppCallCount += 1
        if let e = startWatchAppError { throw e }
    }
}
