import Foundation

public enum WorkoutState: Sendable, Equatable {
    case idle
    case active(startDate: Date)
}
