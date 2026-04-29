import Foundation

enum WorkoutState: Sendable, Equatable {
    case idle
    case active(startDate: Date)
}
