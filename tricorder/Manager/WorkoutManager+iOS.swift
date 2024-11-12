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
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

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
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        /**
         HealthKit calls this handler when a session starts mirroring.
         */
        healthStore.workoutSessionMirroringStartHandler = { mirroredSession in
            Logger.shared.debug(
                "workoutSessionMirroringStartHandler called on Thread \(Thread.current)"
            )

            Task {
                Logger.shared.debug(
                    "workoutSessionMirroringStartHandler Taks running on Thread \(Thread.current)"
                )
                await self.reset()
                await self.setSession(mirroredSession)

                // set object to call when state chnages
                await self.session?.delegate = self

                Logger.shared.log(
                    "Start mirroring remote session: \(mirroredSession)"
                )
            }
        }
    }
}
