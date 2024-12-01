/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that wraps workout operations specific to iOS.
*/

import Foundation
import HealthKit
import OSLog

// MARK: - Workout session management
//
extension WorkoutManager {
    func startWatchWorkout() async throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        // todo: how do I make sure it starts app? do I have to start twice?
        // or make the wake up the watch and only start with a followup request
        // test once have logs
        try await healthStore.startWatchApp(toHandle: HKWorkoutConfiguration())  // This Config is ignored
    }

    func getEndDate() -> Date? {
        return session?.endDate
    }

    func retrieveRemoteSession() {
        Logger.shared.debug("called on Thread \(Thread.current)")

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
