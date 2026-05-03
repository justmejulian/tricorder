#if os(watchOS)
@preconcurrency import HealthKit

// @unchecked Sendable: HKHealthStore is documented as thread-safe by Apple;
// stored immutably after init.
final class HealthKitStore: HealthStoreProtocol, @unchecked Sendable {

    private let store = HKHealthStore()

    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws {
        try await store.requestAuthorization(toShare: toShare, read: read)
    }

    func makeWorkoutSession(configuration: HKWorkoutConfiguration) throws -> any WorkoutSessionProtocol {
        let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
        return HealthKitWorkoutSession(session: session, healthStore: store)
    }
}
#else
// HealthKitStore is unavailable on macOS — watchOS-only HealthKit APIs.
private enum _HealthKitStoreUnavailable {}
#endif
