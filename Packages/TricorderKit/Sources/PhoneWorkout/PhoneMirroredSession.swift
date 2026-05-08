@preconcurrency import HealthKit
import Foundation

// Domain-level observer — decouples PhoneWorkoutManager from HKWorkoutSessionDelegate.
// @MainActor: state mutations happen directly, no Task hop needed.
@MainActor
protocol MirroredSessionObserver: AnyObject {
    func mirroredSessionDidChangeState(to: HKWorkoutSessionState, from: HKWorkoutSessionState, date: Date)
    func mirroredSessionDidFail(error: Error)
    // ⚠️ HOT PATH — do NOT add Logger calls in the implementation.
    func mirroredSessionDidReceiveData(_ data: [Data])
}

protocol MirroredSessionProtocol: AnyObject, Sendable {
    var state: HKWorkoutSessionState { get }
    var startDate: Date? { get }
    @MainActor func setObserver(_ observer: (any MirroredSessionObserver)?)
    func stopActivity(with date: Date)
}

// @unchecked Sendable: HKWorkoutSession is documented thread-safe by Apple;
// observer written once on @MainActor before any delegate callbacks arrive.
final class PhoneMirroredSession: NSObject, MirroredSessionProtocol,
                                  HKWorkoutSessionDelegate, @unchecked Sendable {

    private let session: HKWorkoutSession
    private weak var observer: (any MirroredSessionObserver)?

    init(session: HKWorkoutSession) {
        self.session = session
        super.init()
        session.delegate = self
    }

    var state: HKWorkoutSessionState { session.state }
    var startDate: Date? { session.startDate }

    @MainActor func setObserver(_ observer: (any MirroredSessionObserver)?) {
        self.observer = observer
    }

    func stopActivity(with date: Date) { session.stopActivity(with: date) }

    // MARK: - HKWorkoutSessionDelegate

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor [weak self] in
            self?.observer?.mirroredSessionDidChangeState(to: toState, from: fromState, date: date)
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        Task { @MainActor [weak self] in
            self?.observer?.mirroredSessionDidFail(error: error)
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didReceiveDataFromRemoteWorkoutSession data: [Data]
    ) {
        Task { @MainActor [weak self] in
            self?.observer?.mirroredSessionDidReceiveData(data)
        }
    }
}
