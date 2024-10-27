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
        try await healthStore.startWatchApp(toHandle: configuration)
    }

    func retrieveRemoteSession() {

        Logger.shared.info("\(#function) called")

        /**
         HealthKit calls this handler when a session starts mirroring.
         */
        healthStore.workoutSessionMirroringStartHandler = { mirroredSession in
            Task { @MainActor in
                self.resetWorkout()
                self.session = mirroredSession
                self.session?.delegate = self
                Logger.shared.log(
                    "Start mirroring remote session: \(mirroredSession)")
            }
        }
    }

    func handleReceivedData(_ data: Data) throws {

        Logger.shared.info("\(#function) called: \(data.debugDescription)")

        if let elapsedTime = try? JSONDecoder().decode(
            WorkoutElapsedTime.self, from: data)
        {
            Logger.shared.info("elapsedTime: \(elapsedTime.timeInterval)")

            var currentElapsedTime: TimeInterval = 0
            if session?.state == .running {
                currentElapsedTime =
                    elapsedTime.timeInterval
                    + Date().timeIntervalSince(elapsedTime.date)
            } else {
                currentElapsedTime = elapsedTime.timeInterval
            }

            elapsedTimeInterval = currentElapsedTime

            return
        }

        if let statisticsArray =
            try NSKeyedUnarchiver.unarchivedArrayOfObjects(
                ofClass: HKStatistics.self, from: data)
        {
            Logger.shared.info("statisticsArray: \(statisticsArray.debugDescription)")
            
            for statistics in statisticsArray {
                updateForStatistics(statistics)
            }

            return
        }
    }
    
    /**
     Consume the session state change from the async stream to update sessionState and finish the workout.
     */
    func consumeSessionStateChange(_ change: SessionSateChange) async {
        sessionState = change.newState
    }
}
