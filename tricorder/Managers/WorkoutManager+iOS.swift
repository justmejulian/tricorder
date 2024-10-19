//
//  WorkoutManager+iOS.swift
//  tricorder
//
//  Created by Julian Visser on 05.10.2024.
//

import Foundation
import HealthKit
import os

// MARK: - Workout session management
//
extension WorkoutManager {
  func startWatchWorkout() async throws {
    let configuration = getHKWorkoutConfiguration()
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

      return
    }

    if let statisticsArray = try NSKeyedUnarchiver.unarchivedArrayOfObjects(
      ofClass: HKStatistics.self, from: data)
    {
      for statistics in statisticsArray {
        do {
          // Todo: Had to convert so that could send
          let statisticsStruct = try HKStatisticsStruct(
            statistics: statistics)

          Logger.shared.log("Statistics: \(statisticsStruct.mostRecentQuantity)")

          updateForStatistics(statisticsStruct)
        } catch {
          Logger.shared.error("Failed to update statistics: \(error)")
        }
      }

      return
    }
  }
}
