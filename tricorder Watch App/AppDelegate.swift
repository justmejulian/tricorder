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
            Logger.shared.log("AppDelegate: received workout configuration")
            // todo don't start yet, just say that ready
            await EventManager.shared.trigger(
                key: .companionStartedRecording,
                data: workoutConfiguration
            ) as Void
        }
    }
}
