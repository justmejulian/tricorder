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
        
        try await MotionManager().startUpdates { timestamp, sensor_id, values in
            Logger.shared.debug("Handle motion update: \(timestamp), \(sensor_id), \(values.debugDescription)")
        }

        guard let session else {
            throw WorkoutManagerError.noWorkoutSession
        }

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
    }

    func handleReceivedData(_ data: Data) throws {

        Logger.shared.info("\(#function) called")

        let dataObject = try DataObjectManager().decode(data)

        Logger.shared.info("Received data: \(dataObject.key)")
    }



    func finishedWorkout(date: Date) async throws -> HKWorkout? {
        guard let builder else {
            throw WorkoutManagerError.noLiveWorkoutBuilder
        }
        
        do {
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
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {

        Logger.shared.info("\(#function) called")

        /**
          HealthKit calls this method on an anonymous serial background queue.
          Use Task to provide an asynchronous context so MainActor can come to play.
         */
        Task { @MainActor in
            Logger.shared.info("Task in \(#function) called")
            var allStatistics: [HKStatistics] = []

            for type in collectedTypes {
                if let quantityType = type as? HKQuantityType,
                    // todo: can this be moved to a getStatistics ?
                    // HK statistics to struct
                    let statistics = workoutBuilder.statistics(
                        for: quantityType)
                {
                    //  asynStreamTuple.continuation.yield(sessionSateChange)
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
            await sendData("archived", archivedData)
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(
        _ workoutBuilder: HKLiveWorkoutBuilder
    ) {
        Logger.shared.info("\(#function) called")
    }
}
