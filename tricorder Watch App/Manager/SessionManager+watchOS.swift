//
//  SessionManager+watchOS.swift
//  tricorder
//
//  Created by Julian Visser on 31.10.2024.
//

import Foundation
import os
import HealthKit

extension SessionManager {
    /**
     Consume the session state change from the async stream to update sessionState and finish the workout.
     */
    func consumeSessionStateChange(_ change: SessionSateChange) async {
        sessionState = change.newState
        /**
          Wait for the session to transition states before ending the builder.
         */

        /**
         Send the elapsed time to the iOS side.
         */
        let elapsedTimeInterval =
            session?.associatedWorkoutBuilder().elapsedTime(at: change.date)
            ?? 0
        let elapsedTime = WorkoutElapsedTime(
            timeInterval: elapsedTimeInterval, date: change.date)

        if let elapsedTimeData = try? JSONEncoder().encode(elapsedTime) {
            // Only send elapsedTimeData when running
            if change.newState == .running {
                await sendData(key: "elapsedTime", data: elapsedTimeData)
            }
        }


        if change.newState == .stopped {
            Logger.shared.info("\(#function): Session stopped")
            endWorkout()
        }
    }
    
    func startWorkout(workoutConfiguration: HKWorkoutConfiguration){
        reset()
        try await workoutManager.startWorkout(
            workoutConfiguration: workoutConfiguration)
    }
    
    func endWorkout() {
        session?.end()
        // todo end the rest of the stuff
    }
    
    func handleReceivedData(_ data: Data) throws {
        Logger.shared.info("\(#function) called: \(data.debugDescription)")
        let dataObject = try DataObjectManager().decode(data)
        // todo call others
    }
    
    func resetRest() {
        // todo call other reset stuff
        workoutManager.resetWorkout()
    }
}
