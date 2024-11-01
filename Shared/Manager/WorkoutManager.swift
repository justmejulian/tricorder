/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that wraps the data and operations related to workout.
*/

import Foundation
import HealthKit
import os

actor WorkoutManager: NSObject, ObservableObject {
    /**
     The workout session live states that the UI observes.
     */
    @Published var heartRate: Double = 0
    @Published var elapsedTimeInterval: TimeInterval = 0
    /**
     SummaryView (watchOS) changes from Saving Workout to the metric summary view when
     a workout changes from nil to a valid value.
     */
    @Published var workout: HKWorkout?
    /**
     HealthKit data types to share and read.
     */
    let typesToShare: Set = [
        HKQuantityType.workoutType()
    ]
    let typesToRead: Set = [
        HKQuantityType(.heartRate),
        HKQuantityType.workoutType(),
        HKObjectType.activitySummaryType(),
    ]
    let healthStore = HKHealthStore()
    var sendData: (String, Data) async -> Void
    #if os(watchOS)
        /**
     The live workout builder that is only available on watchOS.
     */
        var builder: HKLiveWorkoutBuilder?
    #else
        /**
     A date for synchronizing the elapsed time between iOS and watchOS.
     */
        var contextDate: Date?

        var workoutSessionMirroringStartHandler: ((HKWorkoutSession) -> Void)
    #endif
    
    init(
        sendData: @escaping (String, Data) async -> Void,
        workoutSessionMirroringStartHandler: @escaping (HKWorkoutSession) -> Void
    ) {
        self.workoutSessionMirroringStartHandler = workoutSessionMirroringStartHandler
        
        self.sendData = sendData
    }
}

// MARK: - Workout session management
//
extension WorkoutManager {
    func resetWorkout() {
        #if os(watchOS)
            builder = nil
        #endif
        workout = nil
        heartRate = 0
    }
}

// MARK: - Workout statistics
//
extension WorkoutManager {
    func updateForStatistics(_ statistics: HKStatistics) {

        Logger.shared.log("\(#function): \(statistics.debugDescription)")

        switch statistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            heartRate =
                statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
                ?? 0

        default:
            return
        }
    }
}

// MARK: - A structure for synchronizing the elapsed time.
//
struct WorkoutElapsedTime: Codable {
    var timeInterval: TimeInterval
    var date: Date
}

// MARK: - Convenient workout state
//
extension HKWorkoutSessionState {
    var isActive: Bool {
        self != .notStarted && self != .ended
    }
}

// MARK: - WorkoutManager Error
//
enum WorkoutManagerError: Error {
    case noWorkoutSession
    case noLiveWorkoutBuilder
    case failedToStartWorkout
    case failedToEndWorkout
    case workoutSessionNotStarted
    case workoutSessionAlreadyStarted
    case workoutSessionEnded
}
