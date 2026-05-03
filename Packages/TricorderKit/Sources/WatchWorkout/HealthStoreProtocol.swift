@preconcurrency import HealthKit

protocol HealthStoreProtocol: Sendable {
    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws
    func makeWorkoutSession(configuration: HKWorkoutConfiguration) throws -> any WorkoutSessionProtocol
}
