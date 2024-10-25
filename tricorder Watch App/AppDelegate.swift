/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate that receives and handles the workout configuration.
*/

import HealthKit
import SwiftUI
import WatchKit
import os

class AppDelegate: NSObject, WKApplicationDelegate {

    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        Task {
            do {
                WorkoutManager.shared.resetWorkout()
                try await WorkoutManager.shared.startWorkout(
                    workoutConfiguration: workoutConfiguration)
                Logger.shared.log("Successfully started workout")
            } catch {
                Logger.shared.log("Failed started workout")
            }
        }
    }
}
