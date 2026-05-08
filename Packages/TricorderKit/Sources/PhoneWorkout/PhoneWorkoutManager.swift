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
public final class PhoneWorkoutManager: NSObject, WorkoutManaging {

    public private(set) var state: WorkoutState = .idle

    private let healthStore: any PhoneHealthStoreProtocol
    private var mirroredSession: (any MirroredSessionProtocol)?

    public override init() {
        self.healthStore = PhoneHealthStore()
        super.init()
        // Register immediately so watch-initiated workouts are received even when
        // the user never taps Start on the phone first.
        registerMirroringHandler()
    }

    /// For testing — inject a fake store.
    init(store: any PhoneHealthStoreProtocol) {
        self.healthStore = store
        super.init()
        registerMirroringHandler()
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
            registerMirroringHandler()
        } catch {
            logger.error("HealthKit authorization failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Controls

    /// Asks HealthKit to launch / wake the watch app and hand it our configuration.
    /// State transitions to .active only after the mirroring handler fires.
    public func startWorkout() async throws {
        // Re-register before each phone-initiated workout as a safety net.
        registerMirroringHandler()

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

    private func registerMirroringHandler() {
        // HealthKit delivers the mirroring handler only once per registration
        // (catch-up delivery of an ended session consumes it). Re-register
        // after each session ends so the next workout is covered regardless of whether
        // it was initiated from the phone or the watch.
        healthStore.setMirroringHandler { [weak self] mirrored in
            logger.info("Mirrored session received from watch")
            Task { @MainActor [weak self] in
                self?.attach(to: mirrored)
            }
        }
    }

    private func attach(to session: any MirroredSessionProtocol) {
        // When the handler is re-registered, HealthKit delivers the previous
        // workout's ended session as "catch-up". Ignore any session that is
        // already in a terminal state so we don't briefly replace mirroredSession
        // with a dead object whose delegate callbacks could clear the real session.
        guard session.state != .ended && session.state != .stopped else {
            logger.info("Ignoring stale mirrored session (state: \(session.state.rawValue))")
            return
        }
        logger.info("Attaching to mirrored session (state: \(session.state.rawValue))")
        mirroredSession = session
        session.setObserver(self)
        // The session may already be .running when the handler fires.
        if session.state == .running {
            state = .active(startDate: session.startDate ?? Date())
        }
    }
}

// MARK: - MirroredSessionObserver

extension PhoneWorkoutManager: MirroredSessionObserver {

    func mirroredSessionDidChangeState(
        to toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        logger.info("Mirrored session state: \(fromState.rawValue) → \(toState.rawValue)")
        switch toState {
        case .running:
            state = .active(startDate: date)
        case .stopped:
            mirroredSession?.setObserver(nil)
            state = .idle
            mirroredSession = nil
            registerMirroringHandler()
        default:
            break
        }
    }

    func mirroredSessionDidFail(error: Error) {
        logger.error("Mirrored session failed: \(error.localizedDescription)")
        mirroredSession?.setObserver(nil)
        state = .idle
        mirroredSession = nil
    }

    // ⚠️ HOT PATH — do NOT add Logger calls here.
    // When motion streaming is active (100 Hz from the watch), this fires
    // continuously. Use OSSignposter for tracing, and log only on errors or
    // at a coarse aggregate rate outside this callback.
    func mirroredSessionDidReceiveData(_ data: [Data]) {}
}
