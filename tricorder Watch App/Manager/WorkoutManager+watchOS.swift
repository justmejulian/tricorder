/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions that wrap workout operations specific to watchOS.
*/

import Foundation
import HealthKit
import os

// MARK: - Workout session management
//
extension WorkoutManager {
    /**
     Use healthStore.requestAuthorization to request authorization in watchOS when
     healthDataAccessRequest isn't available yet.
     */
    func requestAuthorization() {

        Logger.shared.info("\(#function) called")

        Task {
            do {
                try await healthStore.requestAuthorization(
                    toShare: typesToShare, read: typesToRead)
            } catch {
                Logger.shared.log("Failed to request authorization: \(error)")
            }
        }
    }

    func startWorkout(workoutConfiguration: HKWorkoutConfiguration) async throws
    {
        Logger.shared.info("\(#function) called")

        session = try HKWorkoutSession(
            healthStore: healthStore, configuration: workoutConfiguration)

        // todo: does this work?
        guard let session else {
            throw WorkoutManagerError.noWorkoutSession
        }

        // todo: can builder be moved into own file?
        builder = session.associatedWorkoutBuilder()
        session.delegate = self
        builder?.delegate = self
        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore, workoutConfiguration: workoutConfiguration
        )

        // Make sure the session is ready to send data
        session.prepare()

        /**
          Start mirroring the session to the companion device.
         */
        do {
            try await session.startMirroringToCompanionDevice()
        } catch {
            fatalError(
                "Unable to start the mirrored workout: \(error.localizedDescription)"
            )
        }
        /**
          Start the workout session activity.
         */
        let startDate = Date()
        session.startActivity(with: startDate)

        try await builder?.beginCollection(at: startDate)

        // todo: pass this stuff on init of WorkoutManager, pass sendData
        // todo move def of MotionManager into tricorder_Watch_AppApp
        try await MotionManager().startUpdates { timestamp, sensor_id, values in
            //            Logger.shared.debug("Handle motion update: \(timestamp), \(sensor_id), \(values.debugDescription)")
        }

        let nearbyInteractionManager = NearbyInteractionManager()
        nearbyInteractionManager.start()
        if let data = nearbyInteractionManager.getTokenData() {
            await sendData(key: "token", data: data)
        }

    }

    func handleReceivedData(_ data: Data) throws {

        Logger.shared.info("\(#function) called: \(data.debugDescription)")

        guard
            let dataObject = try? JSONDecoder().decode(
                DataObject.self, from: data)
        else {

            Logger.shared.error("Could not decode reciedved data.")
            return
        }
        
        // todo need to beable to dynamiclay add to this
        switch dataObject.key {
        case "token":
            Logger.shared.info(
                "received NIDiscoveryToken \(data) from counterpart")
            
            let nearbyInteractionManager = NearbyInteractionManager()
            nearbyInteractionManager.start()
            nearbyInteractionManager.didReceiveDiscoveryToken(dataObject.data)

        default:
            Logger.shared.error("unknown message key: \(dataObject.key)")
        }
    }

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
                await sendData(
                    key: "elapsedTime", data: elapsedTimeData, retryCount: 1)
            }
        }

        if change.newState == .stopped {
            Logger.shared.info("\(#function): Session stopped")

            do {
                workout = try await finishedWorkout(date: change.date)
            } catch {
                Logger.shared.log("Failed to end workout: \(error))")
                return
            }

            // todo: does this work? should it be an if?
            guard let session else {
                Logger.shared.error("No session to end")

                return
            }

            session.end()
        }
    }

    func finishedWorkout(date: Date) async throws -> HKWorkout? {
        guard let builder else {
            throw WorkoutManagerError.noLiveWorkoutBuilder
        }

        do {
            // todo replace with session?.associatedWorkoutBuilder()
            try await builder.endCollection(at: date)
            return try await builder.finishWorkout()
        } catch {
            throw error
        }

    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
// HealthKit calls the delegate methods on an anonymous serial background queue,
// so the methods need to be nonisolated explicitly.
//
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {

    // todo: is this used?
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {

        Logger.shared.info("\(#function) called")

        /**
          HealthKit calls this method on an anonymous serial background queue.
          Use Task to provide an asynchronous context so MainActor can come to play.
         */
        // todo: move this into StatisticsManager
        Task { @MainActor in
            var allStatistics: [HKStatistics] = []

            for type in collectedTypes {
                if let quantityType = type as? HKQuantityType,
                    let statistics = workoutBuilder.statistics(
                        for: quantityType)
                {
                    updateForStatistics(statistics)
                    allStatistics.append(statistics)
                }
            }

            let archivedData = try? NSKeyedArchiver.archivedData(
                withRootObject: allStatistics, requiringSecureCoding: true)
            guard let archivedData = archivedData, !archivedData.isEmpty else {
                Logger.shared.log("Encoded cycling data is empty")
                return
            }
            /**
              Send a Data object to the connected remote workout session.
             */
            await sendData(
                key: "statisticsArray", data: archivedData, retryCount: 5)
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(
        _ workoutBuilder: HKLiveWorkoutBuilder
    ) {
        Logger.shared.info("\(#function) called")
    }
}
