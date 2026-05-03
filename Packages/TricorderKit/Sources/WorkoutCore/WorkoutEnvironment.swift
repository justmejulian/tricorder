import SwiftUI

extension EnvironmentValues {
    @Entry public var workoutManager: (any WorkoutManaging)? = nil
}
