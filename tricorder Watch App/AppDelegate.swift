//
//  AppDelegate.swift
//  tricorder Watch App
//
//  Created by Julian Visser on 05.10.2024.
//

import HealthKit
import SwiftUI
import WatchKit
import os

class AppDelegate: NSObject, WKApplicationDelegate {

  func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
    Task {
      do {
        WorkoutManager.shared.resetWorkout()
        try await WorkoutManager.shared.startWorkout(workoutConfiguration: workoutConfiguration)
        Logger.shared.log("Successfully started workout")
      } catch {
        Logger.shared.log("Failed started workout: \(error)")
      }
    }
  }
}
