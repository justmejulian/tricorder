//
//  RecordingManager+watchOs.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import HealthKit
import os

extension RecordingManager {
    func registerListeners() async {
        await eventManager.register(
            key: .sessionStateChanged, handleData: self.handleSessionStateChange
        )
    }
}
extension RecordingManager {
    func startRecording(workoutConfiguration: HKWorkoutConfiguration) async {
        do {
            try await workoutManager.startWorkout( workoutConfiguration: workoutConfiguration)
        } catch {
            Logger.shared.error("\(#function) failed : \(error)")
        }

    }
}

extension RecordingManager {
    @Sendable
    nonisolated func handleSessionStateChange(_ data: Sendable) throws {
        Logger.shared.info("\(#function)")

        guard let change = data as? SessionStateChange else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        Logger.shared.info(
            "Session state changed to \(change.newState.rawValue)")

        Task {
            await workoutManager.setSessionSate(newState: change.newState)
        }

        if change.newState == .running {
            Task {
                let elapsedTime = await workoutManager.getWorkoutElapsedTime(
                    date: change.date)

                if let elapsedTimeData = try? JSONEncoder().encode(elapsedTime)
                {
                    await sendData(key: "elapsedTime", data: elapsedTimeData)
                }
            }
        }

        if change.newState == .stopped {
            Logger.shared.info("\(#function): Session stopped")

            // todo stop motion recording

            Task {
                do {
                    try await workoutManager.endWorkout(date: change.date)
                } catch {
                    Logger.shared.error(
                        "\(#function): Error ending workout: \(error)")
                }
            }
        }
    }

}
