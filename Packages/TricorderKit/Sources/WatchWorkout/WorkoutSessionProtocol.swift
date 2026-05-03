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
