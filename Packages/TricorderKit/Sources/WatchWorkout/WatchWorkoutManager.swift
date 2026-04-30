// WatchWorkoutManager.swift — WatchWorkout library
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
import OSLog
import Util
import WorkoutCore

// File-scope private let: a global immutable Sendable value, safe to call from
// any actor context including nonisolated HealthKit delegate callbacks.
private let logger = Logger(subsystem: Logger.subsystem, category: "WatchWorkout")

@Observable
@MainActor
public final class WatchWorkoutManager: NSObject {

    public private(set) var state: WorkoutState = .idle

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    public override init() {
        super.init()
    }

    // MARK: - Authorization

    public func requestAuthorization() async throws {
        let share: Set<HKSampleType> = [.workoutType()]
        let read: Set<HKObjectType> = [
            .workoutType(),
            HKQuantityType(.heartRate),
        ]
        logger.info("Requesting HealthKit authorization")
        do {
            try await healthStore.requestAuthorization(toShare: share, read: read)
            logger.info("HealthKit authorization granted")
        } catch {
            logger.error("HealthKit authorization failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Controls

    /// Called from the watch UI.
    public func startWorkout() async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .unknown
        try await startWorkout(with: config)
    }

    /// Called from WatchAppDelegate when the iPhone initiates via startWatchApp(toHandle:).
    public func startWorkout(with configuration: HKWorkoutConfiguration) async throws {
        guard session == nil else {
            logger.warning("startWorkout called while a session is already active — restarting mirroring")
            try await session?.startMirroringToCompanionDevice()
            return
        }

        logger.info("Starting workout session (activityType: \(configuration.activityType.rawValue))")
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
        logger.info("Mirroring to companion device started")
        newSession.startActivity(with: Date())
        try await newBuilder.beginCollection(at: Date())
        logger.info("Workout session and builder active")
    }

    /// Signals the session to stop; finalization happens in the delegate callback.
    public func stopWorkout() {
        logger.info("Stop requested — ending session activity")
        session?.stopActivity(with: Date())
    }

    // MARK: - Private

    private func finalizeWorkout(endDate: Date) async {
        logger.info("Finalizing workout")
        guard let b = builder else {
            logger.fault("finalizeWorkout called with no active builder")
            return
        }
        do {
            try await b.endCollection(at: endDate)
            try await b.finishWorkout()
            logger.info("Workout saved to HealthKit")
        } catch {
            logger.error("Failed to finalize workout: \(error.localizedDescription)")
        }
        session = nil
        builder = nil
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchWorkoutManager: HKWorkoutSessionDelegate {

    nonisolated public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        // Logger is Sendable — call directly from nonisolated context, before the
        // actor hop, so the log line timestamps the actual HealthKit event.
        logger.info("Session state: \(fromState.rawValue) → \(toState.rawValue)")
        Task { @MainActor [weak self] in
            switch toState {
            case .running:
                self?.state = .active(startDate: date)
            case .stopped:
                self?.state = .idle
                self?.session?.end()
            case .ended:
                await self?.finalizeWorkout(endDate: date)
            default:
                break
            }
        }
    }

    nonisolated public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        logger.error("Workout session failed: \(error.localizedDescription)")
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
    nonisolated public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    // Seam: new quantity samples (HR, cadence, calories) — forward to iPhone or
    // store locally. When motion capture is added, custom HKQuantityType samples
    // from CMMotionManager will arrive here.
    //
    // ⚠️ HOT PATH — do NOT add Logger calls here.
    // At 100 Hz this fires ~100 times/second. Logger persists to disk and will
    // become a bottleneck. For profiling, use OSSignposter instead:
    //
    //   private let signposter = OSSignposter(logger: logger)
    //   let id = signposter.makeSignpostID()
    //   let state = signposter.beginInterval("collectData", id: id)
    //   defer { signposter.endInterval("collectData", state) }
    //
    // Only log errors, or aggregate metrics at a throttled rate (e.g. every Nth call).
    // Never log HKQuantitySample values — that is health data.
    nonisolated public func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {}
}
