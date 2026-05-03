@preconcurrency import HealthKit
import Foundation

// Domain-level observer for builder events.
// @MainActor: matches WatchWorkoutManager isolation; seam methods called directly.
@MainActor
protocol WorkoutBuilderObserver: AnyObject {
    func builderDidCollectEvent()
    func builderDidCollectData(of types: Set<HKSampleType>)
}

protocol WorkoutBuilderProtocol: Sendable {
    var startDate: Date? { get }
    func setObserver(_ observer: (any WorkoutBuilderObserver)?)
    @MainActor func beginCollection(at startDate: Date) async throws
    @MainActor func endCollection(at endDate: Date) async throws
    @MainActor func finishWorkout() async throws
}
