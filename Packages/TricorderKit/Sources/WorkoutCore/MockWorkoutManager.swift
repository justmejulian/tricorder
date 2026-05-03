import Foundation

@Observable
@MainActor
public final class MockWorkoutManager: WorkoutManaging {
    public private(set) var state: WorkoutState = .idle

    public init() {}

    public func requestAuthorization() async throws {}

    public func startWorkout() async throws {
        state = .active(startDate: Date())
    }

    public func stopWorkout() {
        state = .idle
    }
}
