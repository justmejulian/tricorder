// PhoneWorkoutManager.swift — PhoneWorkout library
//
// Responsible for:
//   • Initiating a workout on the watch via HKHealthStore.startWatchApp(toHandle:)
//   • Receiving and observing the mirrored HKWorkoutSession that HealthKit delivers
//     to this process once the watch session starts mirroring.
//   • Exposing WorkoutState so the UI stays in sync with the watch.
//
// Future seams:
//   • didReceiveDataFromRemoteWorkoutSession — motion / analytics data from watch
//   • Persistence: save workout summaries after session ends
//   • Analytics: stream WorkoutState changes to an observer

@preconcurrency import HealthKit
import Foundation
import OSLog
import Util
import WorkoutCore

// File-scope private let: a global immutable Sendable value, safe to call from
// any actor context including nonisolated HealthKit delegate callbacks.
private let logger = Logger(subsystem: Logger.subsystem, category: "PhoneWorkout")

@Observable
@MainActor
public final class PhoneWorkoutManager: NSObject {

    public private(set) var state: WorkoutState = .idle

    private let healthStore = HKHealthStore()
    private var mirroredSession: HKWorkoutSession?

    public override init() {
        super.init()
        // HealthKit delivers the mirrored session on an arbitrary thread;
        // hop to MainActor before touching any mutable state.
        healthStore.workoutSessionMirroringStartHandler = { [weak self] mirrored in
            logger.info("Mirrored session received from watch")
            Task { @MainActor [weak self] in
                self?.attach(to: mirrored)
            }
        }
    }

    // MARK: - Authorization

    public func requestAuthorization() async throws {
        let read: Set<HKObjectType> = [
            .workoutType(),
            HKQuantityType(.heartRate),
        ]
        logger.info("Requesting HealthKit authorization")
        do {
            try await healthStore.requestAuthorization(toShare: [], read: read)
            logger.info("HealthKit authorization granted")
        } catch {
            logger.error("HealthKit authorization failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Controls

    /// Asks HealthKit to launch / wake the watch app and hand it our configuration.
    /// State transitions to .active only after the mirroring handler fires.
    public func startWorkout() async throws {
        logger.info("Requesting watch app launch for workout")
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .unknown
        do {
            try await healthStore.startWatchApp(toHandle: config)
            logger.info("Watch app launch request sent")
        } catch {
            logger.error("Failed to launch watch app: \(error.localizedDescription)")
            throw error
        }
    }

    /// Signals the watch session to stop; the mirrored delegate callback drives
    /// the state back to .idle.
    public func stopWorkout() {
        logger.info("Stop requested — ending mirrored session activity")
        mirroredSession?.stopActivity(with: Date())
    }

    // MARK: - Private

    private func attach(to session: HKWorkoutSession) {
        logger.info("Attaching to mirrored session (state: \(session.state.rawValue))")
        mirroredSession = session
        session.delegate = self
        // The session may already be .running when the handler fires.
        if session.state == .running {
            state = .active(startDate: session.startDate ?? Date())
        }
    }
}

// MARK: - HKWorkoutSessionDelegate

extension PhoneWorkoutManager: HKWorkoutSessionDelegate {

    nonisolated public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        // Logger is Sendable — call directly from nonisolated context.
        logger.info("Mirrored session state: \(fromState.rawValue) → \(toState.rawValue)")
        Task { @MainActor [weak self] in
            switch toState {
            case .running:
                self?.state = .active(startDate: date)
            case .stopped:
                self?.state = .idle
                self?.mirroredSession = nil
            default:
                break
            }
        }
    }

    nonisolated public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        logger.error("Mirrored session failed: \(error.localizedDescription)")
        Task { @MainActor [weak self] in
            self?.state = .idle
            self?.mirroredSession = nil
        }
    }

    // Seam: high-frequency data sent from the watch lands here.
    // Plug in motion streaming / analytics processing when ready.
    //
    // ⚠️ HOT PATH — do NOT add Logger calls here.
    // When motion streaming is active (100 Hz from the watch), this fires
    // continuously. Use OSSignposter for tracing, and log only on errors or
    // at a coarse aggregate rate outside this callback.
    nonisolated public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didReceiveDataFromRemoteWorkoutSession data: [Data]
    ) {}
}
