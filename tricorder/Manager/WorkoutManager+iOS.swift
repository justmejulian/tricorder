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
    func startWatchWorkout(workoutType: HKWorkoutActivityType) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        try await healthStore.startWatchApp(toHandle: configuration)
    }

    func retrieveRemoteSession() {
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
        if let elapsedTime = try? JSONDecoder().decode(
            WorkoutElapsedTime.self, from: data)
        {
            var currentElapsedTime: TimeInterval = 0
            if session?.state == .running {
                currentElapsedTime =
                    elapsedTime.timeInterval
                    + Date().timeIntervalSince(elapsedTime.date)
            } else {
                currentElapsedTime = elapsedTime.timeInterval
            }
            elapsedTimeInterval = currentElapsedTime
        } else if let statisticsArray =
            try NSKeyedUnarchiver.unarchivedArrayOfObjects(
                ofClass: HKStatistics.self, from: data)
        {
            for statistics in statisticsArray {
                updateForStatistics(statistics)
            }
        }
    }
}
