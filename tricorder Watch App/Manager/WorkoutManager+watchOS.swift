/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions that wrap workout operations specific to watchOS.
*/

import Foundation
import HealthKit
import OSLog

// MARK: - Workout session management
//
extension WorkoutManager {
    /**
     Use healthStore.requestAuthorization to request authorization in watchOS when
     healthDataAccessRequest isn't available yet.
     */
    func requestAuthorization() async throws {
        Logger.shared.info("Request authorization")
        try await healthStore.requestAuthorization(
            toShare: typesToShare,
            read: typesToRead
        )
    }

    func createHKWorkoutSession(configuration: HKWorkoutConfiguration) throws -> HKWorkoutSession {
        do {
            return try HKWorkoutSession(
                healthStore: healthStore,
                configuration: configuration
            )
        } catch {
            Logger.shared.error("\(error)")
            throw WorkoutManagerError.failedToCreateWorkoutSession
        }
    }

    func startWorkout() async throws -> Date {
        Logger.shared.info("Starting workout")

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .functionalStrengthTraining
        configuration.locationType = .indoor

        self.session = try createHKWorkoutSession(configuration: configuration)

        guard let session = self.session else {
            throw WorkoutManagerError.noWorkoutSession
        }

        builder = session.associatedWorkoutBuilder()
        session.delegate = self
        builder?.delegate = self
        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )

        // Make sure the session is ready to send data
        session.prepare()

        /**
          Start mirroring the session to the companion device.
         */
        do {
            try await session.startMirroringToCompanionDevice()
        } catch {
            // todo what about when no iphone?
            fatalError(
                "Unable to start the mirrored workout: \(error.localizedDescription)"
            )
        }
        /**
          Start the workout session activity.
         */
        let startDate = Date()
        do {
            session.startActivity(with: startDate)
            try await builder?.beginCollection(at: startDate)

            statisticsManager = StatisticsManager(recordingStartDate: startDate)

            return startDate
        } catch {
            Logger.shared.error("\(error)")
            throw WorkoutManagerError.failedToStartWorkout
        }
    }

    func endWorkout(date: Date) async throws {
        Logger.shared.info("End workout")

        do {
            workout = try await finishedWorkout(date: date)
        } catch {
            Logger.shared.log("Failed to end workout: \(error))")
            return
        }

        session?.end()
    }

    func getStartDate() -> Date? {
        session?.associatedWorkoutBuilder().startDate
    }

    func getElapsedTime(at: Date? = nil) -> TimeInterval? {
        if let at = at {
            return builder?.elapsedTime(at: at)
        }

        return builder?.elapsedTime
    }

    func finishedWorkout(date: Date) async throws -> HKWorkout? {
        guard let builder else {
            throw WorkoutManagerError.noLiveWorkoutBuilder
        }
        if builder.workoutSession?.state == .ended {
            return nil
        }

        if builder.startDate != nil {
            try await builder.endCollection(at: date)
        }

        if builder.workoutSession?.state == .stopped {
            return nil
        }

        return try await builder.finishWorkout()
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

        /**
          HealthKit calls this method on an anonymous serial background queue.
          Use Task to provide an asynchronous context so MainActor can come to play.
         */
        Task { @MainActor in
            guard let statisticsManager = await statisticsManager else {
                Logger.shared.error("Recieved didCollectDataOf while statisticsManager is nil")
                return
            }

            for type in collectedTypes {
                if let quantityType = type as? HKQuantityType,
                    let statistics = workoutBuilder.statistics(
                        for: quantityType
                    )
                {
                    await statisticsManager.handle(statistics)
                }
            }
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(
        _ workoutBuilder: HKLiveWorkoutBuilder
    ) {

        Logger.shared.debug("called.")
    }
}
