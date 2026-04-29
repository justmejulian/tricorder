// WatchWorkoutManager.swift — watchOS target
//
// Responsible for:
//   • Owning the HKWorkoutSession — the watch is the source of truth.
//   • Mirroring session state to the companion iPhone automatically via HealthKit.
//   • Collecting workout data through HKLiveWorkoutBuilder and saving to HealthKit
//     when the session ends.
//
// Future seams:
//   • workoutBuilder(_:didCollectDataOf:) — process HR, cadence, or custom quantities
//   • workoutBuilderDidCollectEvent(_:) — log workout events (sets, reps, laps)
//   • sendToRemoteWorkoutSession(_:data:) — stream motion data to iPhone at 100 Hz
//   • Replace HKLiveWorkoutDataSource with a custom source for CMMotionManager data

@preconcurrency import HealthKit
import Foundation

@Observable
@MainActor
final class WatchWorkoutManager: NSObject {

    private(set) var state: WorkoutState = .idle

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    // MARK: - Authorization

    func requestAuthorization() async throws {
        let share: Set<HKSampleType> = [.workoutType()]
        let read: Set<HKObjectType> = [
            .workoutType(),
            HKQuantityType(.heartRate),
        ]
        try await healthStore.requestAuthorization(toShare: share, read: read)
    }

    // MARK: - Controls

    /// Called from the watch UI.
    func startWorkout() async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .unknown
        try await startWorkout(with: config)
    }

    /// Called from WatchAppDelegate when the iPhone initiates via startWatchApp(toHandle:).
    func startWorkout(with configuration: HKWorkoutConfiguration) async throws {
        guard session == nil else { return }

        let newSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        let newBuilder = newSession.associatedWorkoutBuilder()
        newBuilder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )

        newSession.delegate = self
        newBuilder.delegate = self

        session = newSession
        builder = newBuilder

        // Mirror first so the iPhone receives the session as soon as activity starts.
        try await newSession.startMirroringToCompanionDevice()
        newSession.startActivity(with: Date())
        try await newBuilder.beginCollection(at: Date())
    }

    /// Signals the session to stop; finalization happens in the delegate callback.
    func stopWorkout() {
        session?.stopActivity(with: Date())
    }

    // MARK: - Private

    private func finalizeWorkout(endDate: Date) async {
        guard let b = builder else { return }
        do {
            try await b.endCollection(at: endDate)
            try await b.finishWorkout()
        } catch {
            // Future: surface to error reporting / retry logic
        }
        session = nil
        builder = nil
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchWorkoutManager: HKWorkoutSessionDelegate {

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor [weak self] in
            switch toState {
            case .running:
                self?.state = .active(startDate: date)
            case .stopped:
                self?.state = .idle
                await self?.finalizeWorkout(endDate: date)
            default:
                break
            }
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        Task { @MainActor [weak self] in
            self?.state = .idle
            self?.session = nil
            self?.builder = nil
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {

    // Seam: workout events (sets, laps, markers) — process or relay to iPhone here.
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    // Seam: new quantity samples (HR, cadence, calories) — forward to iPhone or
    // store locally. When motion capture is added, custom HKQuantityType samples
    // from CMMotionManager will arrive here.
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {}
}
