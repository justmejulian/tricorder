//
//  SessionManager.swift
//  tricorder
//
//  Created by Julian Visser on 31.10.2024.
//

import Foundation
import HealthKit
import os

@MainActor
class SessionManager: NSObject, ObservableObject {
    static let shared = SessionManager()

    struct SessionSateChange {
        let newState: HKWorkoutSessionState
        let date: Date
    }

    @Published var sessionState: HKWorkoutSessionState = .notStarted

    var session: HKWorkoutSession?
    /**
     Creates an async stream that buffers a single newest element, and the stream's continuation to yield new elements synchronously to the stream.
     The Swift actors don't handle tasks in a first-in-first-out way. Use AsyncStream to make sure that the app presents the latest state.
     */
    let asynStreamTuple = AsyncStream.makeStream(
        of: SessionSateChange.self, bufferingPolicy: .bufferingNewest(1))
    
    var workoutManager: WorkoutManager

    private override init() {
        
        super.init()
        
        self.workoutManager = WorkoutManager(
            sendData: self.sendData,
            workoutSessionMirroringStartHandler: self.workoutSessionMirroringStartHandler
            )

        /**
         Kick off a task to consume the async stream. The next value in the stream can't start processing
         until "await consumeSessionStateChange(value)" returns and the loop enters the next iteration, which serializes the asynchronous operations.
         */
        Task {
            for await value in asynStreamTuple.stream {
                await consumeSessionStateChange(value)
            }
        }
        
    }
}
// MARK: - Public session management
//
extension SessionManager {
    func reset() {
        session = nil
        sessionState = .notStarted

        resetRest()
    }

    nonisolated func sendData(_ key: String, _ data: Data) async {
        do {
            let dataObject = try DataObjectManager().encode(
                key: key, data: data)
            await sendData(dataObject)
        } catch {
            Logger.shared.error("Could not encode data for key : \(key)")
        }
    }

}
// MARK: - Private session management
//
extension SessionManager {
    fileprivate func sendData(_ data: Data, retryCount: Int = 0) async {

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
// MARK: - HKWorkoutSessionDelegate
// HealthKit calls the delegate methods on an anonymous serial background queue,
// so the methods need to be nonisolated explicitly.
//
extension SessionManager: HKWorkoutSessionDelegate {
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
