/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that wraps the data and operations related to workout.
*/

import Foundation
import HealthKit
import os

@MainActor
class WorkoutManager: NSObject, ObservableObject {
    struct SessionSateChange {
        let newState: HKWorkoutSessionState
        let date: Date
    }
    /**
     The workout session live states that the UI observes.
     */
    @Published var sessionState: HKWorkoutSessionState = .notStarted
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
    var session: HKWorkoutSession?
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
    #endif
    /**
     Creates an async stream that buffers a single newest element, and the stream's continuation to yield new elements synchronously to the stream.
     The Swift actors don't handle tasks in a first-in-first-out way. Use AsyncStream to make sure that the app presents the latest state.
     */
    let asynStreamTuple = AsyncStream.makeStream(
        of: SessionSateChange.self, bufferingPolicy: .bufferingNewest(1))
    /**
     WorkoutManager is a singleton.
     */
    static let shared = WorkoutManager()

    /**
     Kick off a task to consume the async stream. The next value in the stream can't start processing
     until "await consumeSessionStateChange(value)" returns and the loop enters the next iteration, which serializes the asynchronous operations.
     */
    private override init() {
        super.init()
        Task {
            for await value in asynStreamTuple.stream {
                await consumeSessionStateChange(value)
            }
        }
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
        session = nil
        heartRate = 0
        sessionState = .notStarted
    }

    func sendData(_ data: Data, retryCount: Int = 0) async {

        Logger.shared.info(
            "\(#function) data: \(data.debugDescription) retry count: \(retryCount)"
        )

        do {
            try await session?.sendToRemoteWorkoutSession(data: data)
        } catch {
            // todo make a retry wrapper function
            if retryCount > 0 {
                Logger.shared.log(
                    "Failed to send data, retrying: \(retryCount)")

                // Todo: maybe restart session?

                do {
                    let oneSecond = UInt64(1_000_000_000)
                    try await Task.sleep(nanoseconds: oneSecond)
                } catch {
                    Logger.shared.error("Failed to sleep: \(error)")
                }

                await sendData(data, retryCount: retryCount - 1)
                return
            }
            Logger.shared.log("Failed to send data: \(error)")
        }
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

// MARK: - HKWorkoutSessionDelegate
// HealthKit calls the delegate methods on an anonymous serial background queue,
// so the methods need to be nonisolated explicitly.
//
extension WorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Logger.shared.log(
            "Session state changed from \(fromState.rawValue) to \(toState.rawValue)"
        )
        /**
         Yield the new state change to the async stream synchronously.
         asynStreamTuple is a constant, so it's nonisolated.
         */
        let sessionSateChange = SessionSateChange(newState: toState, date: date)
        asynStreamTuple.continuation.yield(sessionSateChange)
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        Logger.shared.log("\(#function): \(error)")
    }

    /**
     HealthKit calls this method when it determines that the mirrored workout session is invalid.
     */
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didDisconnectFromRemoteDeviceWithError error: Error?
    ) {
        Logger.shared.log("\(#function): \(error)")
    }

    /**
     In iOS, the sample app can go into the background and become suspended.
     When suspended, HealthKit gathers the data coming from the remote session.
     When the app resumes, HealthKit sends an array containing all the data objects it has accumulated to this delegate method.
     The data objects in the array appear in the order that the local system received them.

     On watchOS, the workout session keeps the app running even if it is in the background; however, the system can
     temporarily suspend the app — for example, if the app uses an excessive amount of CPU in the background.
     While suspended, HealthKit caches the incoming data objects and delivers an array of data objects when the app resumes, just like in the iOS app.
     */
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didReceiveDataFromRemoteWorkoutSession data: [Data]
    ) {
        Logger.shared.log("\(#function): \(data.debugDescription)")
        Task { @MainActor in
            do {
                for anElement in data {
                    try handleReceivedData(anElement)
                }
            } catch {
                Logger.shared.log("Failed to handle received data: \(error))")
            }
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
