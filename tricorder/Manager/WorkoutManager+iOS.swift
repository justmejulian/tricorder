/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that wraps workout operations specific to iOS.
*/

import Foundation
import HealthKit
import os

// MARK: - Workout session management
//
extension WorkoutManager {
    func startWatchWorkout() async throws {

        Logger.shared.info("\(#function) called")

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .functionalStrengthTraining
        configuration.locationType = .indoor

        // todo: how do I make sure it starts app?
        try await healthStore.startWatchApp(toHandle: configuration)
    }

    func getEndDate() -> Date? {
        return session?.endDate
    }

    func retrieveRemoteSession() {
        Logger.shared.info("\(#function) called")

        // todo when called?

        /**
         HealthKit calls this handler when a session starts mirroring.
         */
        healthStore.workoutSessionMirroringStartHandler = { mirroredSession in
            Task { @MainActor in
                self.resetWorkout()
                self.session = mirroredSession
                self.session?.delegate = self
                Logger.shared.log(
                    "Start mirroring remote session: \(mirroredSession)"
                )
            }
        }
    }
}
