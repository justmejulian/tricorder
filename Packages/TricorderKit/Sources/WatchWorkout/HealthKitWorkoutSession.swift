@preconcurrency import HealthKit
import Foundation

// Domain-level observer — decouples WatchWorkoutManager from HealthKit delegate protocols.
// @MainActor: state mutations happen directly, no Task hop needed.
@MainActor
protocol WorkoutSessionObserver: AnyObject {
    func sessionDidChangeState(to: HKWorkoutSessionState, from: HKWorkoutSessionState, date: Date)
    func sessionDidFail(error: Error)
}

protocol WorkoutSessionProtocol: Sendable {
    func setObserver(_ observer: (any WorkoutSessionObserver)?)
    func makeBuilder() -> any WorkoutBuilderProtocol
    func prepare()
    func startMirroringToCompanionDevice() async throws
    func startActivity(with startDate: Date)
    func stopActivity(with date: Date)
    func end()
}

#if os(watchOS)
// @unchecked Sendable: HKWorkoutSession is thread-safe per Apple docs;
// observer written once on @MainActor before any delegate callbacks arrive.
final class HealthKitWorkoutSession: NSObject, WorkoutSessionProtocol,
                                     HKWorkoutSessionDelegate, @unchecked Sendable {

    private let session: HKWorkoutSession
    private let healthStore: HKHealthStore
    private weak var observer: (any WorkoutSessionObserver)?

    init(session: HKWorkoutSession, healthStore: HKHealthStore) {
        self.session = session
        self.healthStore = healthStore
        super.init()
        session.delegate = self
    }

    func setObserver(_ observer: (any WorkoutSessionObserver)?) {
        self.observer = observer
    }

    func makeBuilder() -> any WorkoutBuilderProtocol {
        // No HKLiveWorkoutDataSource — see WatchWorkoutManager.beginCollection comment.
        HealthKitWorkoutBuilder(builder: session.associatedWorkoutBuilder())
    }

    func prepare() { session.prepare() }

    func startMirroringToCompanionDevice() async throws {
        try await session.startMirroringToCompanionDevice()
    }

    func startActivity(with startDate: Date) { session.startActivity(with: startDate) }
    func stopActivity(with date: Date) { session.stopActivity(with: date) }
    func end() { session.end() }

    // MARK: - HKWorkoutSessionDelegate

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor [weak self] in
            self?.observer?.sessionDidChangeState(to: toState, from: fromState, date: date)
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        Task { @MainActor [weak self] in
            self?.observer?.sessionDidFail(error: error)
        }
    }
}
#endif
