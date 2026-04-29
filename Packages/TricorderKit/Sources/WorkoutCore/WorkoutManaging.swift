public protocol WorkoutManaging: AnyObject {
    var state: WorkoutState { get }
    func requestAuthorization() async throws
    func startWorkout() async throws
    func stopWorkout()
}
