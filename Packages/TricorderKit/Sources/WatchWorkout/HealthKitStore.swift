@preconcurrency import HealthKit

protocol HealthStoreProtocol: Sendable {
    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws
    func makeWorkoutSession(configuration: HKWorkoutConfiguration) throws -> any WorkoutSessionProtocol
}

#if os(watchOS)
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
#endif
