// PhoneWorkoutManager.swift — iOS target
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

@Observable
@MainActor
final class PhoneWorkoutManager: NSObject {

    private(set) var state: WorkoutState = .idle

    private let healthStore = HKHealthStore()
    private var mirroredSession: HKWorkoutSession?

    override init() {
        super.init()
        // HealthKit delivers the mirrored session on an arbitrary thread;
        // hop to MainActor before touching any mutable state.
        healthStore.workoutSessionMirroringStartHandler = { [weak self] mirrored in
            Task { @MainActor [weak self] in
                self?.attach(to: mirrored)
            }
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        let read: Set<HKObjectType> = [
            .workoutType(),
            HKQuantityType(.heartRate),
        ]
        try await healthStore.requestAuthorization(toShare: [], read: read)
    }

    // MARK: - Controls

    /// Asks HealthKit to launch / wake the watch app and hand it our configuration.
    /// State transitions to .active only after the mirroring handler fires.
    func startWorkout() async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .unknown
        try await healthStore.startWatchApp(toHandle: config)
    }

    /// Signals the watch session to stop; the mirrored delegate callback drives
    /// the state back to .idle.
    func stopWorkout() {
        mirroredSession?.stopActivity(with: Date())
    }

    // MARK: - Private

    private func attach(to session: HKWorkoutSession) {
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
                self?.mirroredSession = nil
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
            self?.mirroredSession = nil
        }
    }

    // Seam: high-frequency data sent from the watch lands here.
    // Plug in motion streaming / analytics processing when ready.
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didReceiveDataFromRemoteWorkoutSession data: [Data]
    ) {}
}
