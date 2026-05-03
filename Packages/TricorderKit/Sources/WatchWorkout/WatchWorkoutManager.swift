// WatchWorkoutManager.swift — WatchWorkout library
//
// Responsible for:
//   • Owning the HKWorkoutSession — the watch is the source of truth.
//   • Mirroring session state to the companion iPhone automatically via HealthKit.
//   • Collecting workout data through HKLiveWorkoutBuilder and saving to HealthKit
//     when the session ends.
//
// Future seams:
//   • builderDidCollectData(of:) — process HR, cadence, or custom quantities
//   • builderDidCollectEvent() — log workout events (sets, reps, laps)
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
public final class WatchWorkoutManager: WorkoutManaging {

    public private(set) var state: WorkoutState = .idle

    private let store: any HealthStoreProtocol
    private var session: (any WorkoutSessionProtocol)?
    private var builder: (any WorkoutBuilderProtocol)?

    #if os(watchOS)
    public convenience init() {
        self.init(store: HealthKitStore())
    }
    #endif

    init(store: any HealthStoreProtocol) {
        self.store = store
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
            try await store.requestAuthorization(toShare: share, read: read)
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
            logger.warning("startWorkout called while a session is already active — ignoring")
            return
        }

        logger.info("Starting workout session (activityType: \(configuration.activityType.rawValue))")
        let newSession = try store.makeWorkoutSession(configuration: configuration)
        let newBuilder = newSession.makeBuilder()

        newSession.setObserver(self)
        newBuilder.setObserver(self)

        session = newSession
        builder = newBuilder

        newSession.prepare()

        // Mirror first so the iPhone receives the session as soon as activity starts.
        try await newSession.startMirroringToCompanionDevice()
        logger.info("Mirroring to companion device started")
        newSession.startActivity(with: Date())
    }

    /// Signals the session to stop; finalization happens in the observer callback.
    public func stopWorkout() {
        logger.info("Stop requested — ending session activity")
        session?.stopActivity(with: Date())
    }

    // MARK: - Private

    private func beginCollection(at date: Date) async {
        guard let b = builder else { return }
        // No HKLiveWorkoutDataSource: setting one before the session is running
        // causes HealthKit to sync its data-type config with the companion device
        // during mirroring setup, which fails (the mirrored session on iPhone has
        // no builder) and drives the builder into terminal Error(7). Without a
        // data source, beginCollection only needs .workoutType write auth, which
        // we already hold, and still tracks workout duration and events correctly.
        // Health metrics (HR, calories) can be added via a custom data source once
        // the right toShare types are added to requestAuthorization.
        do {
            try await b.beginCollection(at: date)
            logger.info("Workout data collection started")
        } catch {
            logger.error("beginCollection failed: \(error.localizedDescription)")
        }
    }

    private func finalizeWorkout(endDate: Date) async {
        logger.info("Finalizing workout")
        guard let b = builder else {
            logger.fault("finalizeWorkout called with no active builder")
            session = nil
            return
        }
        // Clear references before any await so a new workout can start immediately.
        session = nil
        builder = nil
        // beginCollection may have failed (e.g. due to a builder state-machine error),
        // in which case startDate is nil and endCollection would throw
        // "cannot set endDate without a startDate".
        guard b.startDate != nil else {
            logger.warning("Builder has no start date — workout was never collected, skipping finalization")
            return
        }
        do {
            try await b.endCollection(at: endDate)
            try await b.finishWorkout()
            logger.info("Workout saved to HealthKit")
        } catch {
            logger.error("Failed to finalize workout: \(error.localizedDescription)")
        }
    }
}

// MARK: - WorkoutSessionObserver

extension WatchWorkoutManager: WorkoutSessionObserver {

    func sessionDidChangeState(
        to toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        logger.info("Session state: \(fromState.rawValue) → \(toState.rawValue)")
        switch toState {
        case .running:
            state = .active(startDate: date)
            Task { await self.beginCollection(at: date) }
        case .stopped:
            state = .idle
            session?.end()
        case .ended:
            Task { await self.finalizeWorkout(endDate: date) }
        default:
            break
        }
    }

    func sessionDidFail(error: Error) {
        logger.error("Workout session failed: \(error.localizedDescription)")
        state = .idle
        session = nil
        builder = nil
    }
}

// MARK: - WorkoutBuilderObserver

extension WatchWorkoutManager: WorkoutBuilderObserver {

    // Seam: workout events (sets, laps, markers) — process or relay to iPhone here.
    func builderDidCollectEvent() {}

    // Seam: new quantity samples (HR, cadence, calories) — forward to iPhone or store locally.
    // ⚠️ HOT PATH — do NOT add Logger calls here.
    func builderDidCollectData(of types: Set<HKSampleType>) {}
}
