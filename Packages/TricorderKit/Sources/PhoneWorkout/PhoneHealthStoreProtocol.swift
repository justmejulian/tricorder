// PhoneHealthStoreProtocol.swift — PhoneWorkout library
//
// Abstracts the HKHealthStore surface used by PhoneWorkoutManager so the
// manager can be tested without a live HealthKit stack.

@preconcurrency import HealthKit

protocol PhoneHealthStoreProtocol: Sendable {
    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws
    /// Assigns the handler HealthKit calls when a mirrored Watch session arrives.
    /// Called on @MainActor — mirrors the isolation of PhoneWorkoutManager.
    @MainActor func setMirroringHandler(_ handler: (@Sendable (HKWorkoutSession) -> Void)?)
    func startWatchApp(toHandle configuration: HKWorkoutConfiguration) async throws
}

// @unchecked Sendable: HKHealthStore is documented as thread-safe by Apple;
// stored immutably after init.
final class PhoneHealthStore: PhoneHealthStoreProtocol, @unchecked Sendable {

    private let store = HKHealthStore()

    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws {
        try await store.requestAuthorization(toShare: toShare, read: read)
    }

    @MainActor func setMirroringHandler(_ handler: (@Sendable (HKWorkoutSession) -> Void)?) {
        store.workoutSessionMirroringStartHandler = handler
    }

    func startWatchApp(toHandle configuration: HKWorkoutConfiguration) async throws {
        try await store.startWatchApp(toHandle: configuration)
    }
}
