/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that wraps the data and operations related to workout.
*/

import Foundation
import HealthKit
import OSLog

actor WorkoutManager: NSObject {
    var workout: HKWorkout?

    /// HealthKit data types to share and read.
    let typesToShare: Set = [
        HKQuantityType.workoutType()
    ]

    let typesToRead: Set = [
        HKQuantityType(.heartRate),
        HKQuantityType.workoutType(),
        // todo can this be removed? (i guess requires reinstall)
        HKObjectType.activitySummaryType(),
    ]
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?

    var eventManager = EventManager.shared

    #if os(watchOS)
        var builder: HKLiveWorkoutBuilder?
        var statisticsManager: StatisticsManager?
    #else
    #endif

    func setSession(_ session: HKWorkoutSession) {

        self.session = session
    }

    func getSession() -> HKWorkoutSession? {
        return session
    }
}

// MARK: - Workout session management
//
extension WorkoutManager {
    func reset() {
        #if os(watchOS)
            builder = nil
            statisticsManager = nil
        #endif
        workout = nil
        session = nil
    }

    func stop() {
        Logger.shared.info("Stop Activity")

        session?.stopActivity(
            with: .now
        )
    }

    func sendCodable(key: String, data: Data) async throws {
        let dataObject = try SendDataObjectManager().encode(
            key: key,
            data: data
        )

        try await sendData(dataObject, retryCount: 0)
    }

    func sendData(_ data: Data, retryCount: Int = 0) async throws {
        do {
            try await session?.sendToRemoteWorkoutSession(data: data)
        } catch {
            // todo make a retry wrapper function
            if retryCount > 0 {
                Logger.shared.log(
                    "Failed to send data, retrying: \(retryCount)"
                )

                // Todo: maybe restart session?

                do {
                    let oneSecond = UInt64(1_000_000_000)
                    try await Task.sleep(nanoseconds: oneSecond)
                } catch {
                    Logger.shared.error("Failed to sleep: \(error)")
                }

                try await sendData(data, retryCount: retryCount - 1)
                return
            }

            throw WorkoutManagerError.failedToSendData
        }
    }

    nonisolated func handleSessionSateChange(_ sessionSateChange: SessionStateChange) {
        Task {
            await eventManager.trigger(
                key: .sessionStateChanged,
                data: sessionSateChange
            ) as Void
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
        Logger.shared.debug(
            "Session state changed from \(fromState.rawValue) to \(toState.rawValue)"
        )
        /**
         Yield the new state change to the async stream synchronously.
         asynStreamTuple is a constant, so it's nonisolated.
         */
        let sessionSateChange = SessionStateChange(
            newState: toState,
            date: date
        )

        handleSessionSateChange(sessionSateChange)
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
        // todo: is main needed?
        Task { @MainActor in
            for anElement in data {
                await eventManager.trigger(
                    key: .receivedWorkoutData,
                    data: anElement
                ) as Void
            }
        }
    }
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
    case failedToSendData
    case workoutSessionNotStarted
    case workoutSessionAlreadyStarted
    case workoutSessionEnded
}

// MARK: - SessionSateChange
//
struct SessionStateChange: Sendable {
    let newState: HKWorkoutSessionState
    let date: Date
}
