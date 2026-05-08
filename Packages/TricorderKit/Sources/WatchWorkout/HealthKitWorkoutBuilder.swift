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

// @unchecked Sendable: HKLiveWorkoutBuilder is thread-safe per Apple docs;
// observer written once on @MainActor before any delegate callbacks arrive.
final class HealthKitWorkoutBuilder: NSObject, WorkoutBuilderProtocol,
                                     HKLiveWorkoutBuilderDelegate, @unchecked Sendable {

    private let builder: HKLiveWorkoutBuilder
    private weak var observer: (any WorkoutBuilderObserver)?

    init(builder: HKLiveWorkoutBuilder) {
        self.builder = builder
        super.init()
        builder.delegate = self
    }

    var startDate: Date? { builder.startDate }

    func setObserver(_ observer: (any WorkoutBuilderObserver)?) {
        self.observer = observer
    }

    @MainActor func beginCollection(at startDate: Date) async throws {
        try await builder.beginCollection(at: startDate)
    }

    @MainActor func endCollection(at endDate: Date) async throws {
        try await builder.endCollection(at: endDate)
    }

    @MainActor func finishWorkout() async throws {
        try await builder.finishWorkout()
    }

    // MARK: - HKLiveWorkoutBuilderDelegate

    // Seam: workout events (sets, laps, markers).
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        Task { @MainActor [weak self] in self?.observer?.builderDidCollectEvent() }
    }

    // ⚠️ HOT PATH — do NOT add Logger calls here.
    // At 100 Hz this fires ~100 times/second. Use OSSignposter for tracing instead.
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        Task { @MainActor [weak self] in self?.observer?.builderDidCollectData(of: collectedTypes) }
    }
}
