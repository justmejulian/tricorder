//
//  RecordingManager+watchOs.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import HealthKit
import os

extension RecordingManager {
    func registerListeners() async {
        Logger.shared.debug("called on Thread \(Thread.current)")

        await eventManager.register(
            key: .sessionStateChanged,
            handleData: self.handleSessionStateChange
        )

        await eventManager.register(
            key: .receivedData,
            handleData: self.handleReceivedData
        )

        await eventManager.register(
            key: .receivedWorkoutData,
            handleData: self.handleReceivedWorkoutData
        )

        await eventManager.register(
            key: .collectedDistance,
            handleData: self.handleReceivedDistance
        )
    }

    func resetRest() {

    }
}

// MARK: -  RecordingManager functions
//
extension RecordingManager {
    // todo add name: String?
    func startRecording() async throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        Logger.shared.info("Starting Recording")

        await reset()

        do {
            try await workoutManager.startWatchWorkout()

        } catch {
            Logger.shared.log(
                "Failed to start cycling on the paired watch."
            )
            throw RecordingManagerError.startWorkout
        }
    }

    func stopRecording() async {
        await workoutManager.stop()
    }

    func fetchRemoteRecordingState() async {
        Logger.shared.debug("called on Thread \(Thread.current)")
        do {
            guard
                let recordingStateData = try await connectivityManager.sendData(
                    key: "recordingState",
                    data: JSONEncoder().encode([] as [Int])  // send empty data
                )
            else {
                throw RecordingManagerError.invalidData
            }

            let recordingObject = try JSONDecoder().decode(
                RecordingObject.self,
                from: recordingStateData
            )
            self.recordingState = HKWorkoutSessionState(rawValue: recordingObject.recordingState)!
            if let startTime = recordingObject.startTime {
                self.startDate = Date(timeIntervalSince1970: startTime)
            }
            // todo also do something about the motionData count
        } catch {
            Logger.shared.error("Failed to send request for recording state: \(error)")
        }
    }
}

// MARK: -  RecordingManager handlers
//
extension RecordingManager {
    @Sendable
    nonisolated func handleSessionStateChange(_ data: Sendable) throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        guard let change = data as? SessionStateChange else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        Logger.shared.info(
            "Session state changed to \(change.newState.rawValue)"
        )

        Task {
            let currentState = await getRecordingState()

            if change.newState == currentState {
                return
            }

            if change.newState == .running {
                await reset()
            }

            await setRecordingState(newState: change.newState)
        }

    }

    @Sendable
    nonisolated func handleReceivedData(_ data: Sendable) async throws -> Data? {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let dataObject = try SendDataObjectManager().decode(data)

        // todo move these keys into and enum, so I know what is possible
        switch dataObject.key {
        case "discoveryToken":
            try await nearbyInteractionManager.setDiscoveryToken(dataObject.data)
            // return own DiscoveryToken
            let token = try await nearbyInteractionManager.getDiscoveryTokenData()
            await nearbyInteractionManager.start()
            return token

        case "sensorUpdate":
            //            await heartRateManager.update(
            let sensor = try JSONDecoder().decode(
                Sensor.self,
                from: dataObject.data
            )

            try await storeSensor(sensor)

            await updateObservableManagers(sensor: sensor)

            // todo return something better
            return nil
        default:
            throw RecordingManagerError.noKey
        }
    }

    @Sendable
    nonisolated func handleReceivedWorkoutData(_ data: Sendable) throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let dataObject = try SendDataObjectManager().decode(data)

        // todo move these keys into and enum, so I know what is possible
        switch dataObject.key {

        // todo can I replace this with the changeState?
        case "startDate":
            Task {
                let date = try JSONDecoder().decode(
                    Date.self,
                    from: dataObject.data

                )

                try await storeRecording(name: nil, date: date)

                await setStartDate(date)
            }

        default:
            Logger.shared.error("\(#function): Unknown dataObject key: \(dataObject.key)")
        }
    }

    @Sendable
    nonisolated func handleReceivedDistance(_ data: Sendable) throws {
        Logger.shared.debug("called on Thread \(Thread.current)")
        Task {
            guard let recordingStartDate = await startDate else {
                Logger.shared.error("Tried to set distance, but start date is nil.")
                return
            }

            guard let distanceValue = data as? DistanceValue else {
                Logger.shared.error("\(#function): Invalid data type")
                return
            }

            let sensor = Sensor.distance(
                .distance,
                recordingStartDate: recordingStartDate,
                batch: distanceValue
            )

            try await storeSensor(sensor)

            await distanceManager.update(data: data)
        }
    }
}

// MARK: -  RecordingManager Data handlers
//
extension RecordingManager {
    func storeSensor(_ sensor: Sensor) async throws {
        let handler = SensorBackgroundDataHandler(modelContainer: modelContainer)
        try await handler.add(sensor: sensor)
    }

    func storeRecording(name: String?, date: Date) async throws {
        let recordingBackgroundDataHandler = RecordingBackgroundDataHandler(
            modelContainer: modelContainer
        )

        // todo use recordingname
        try await recordingBackgroundDataHandler.addNewRecording(
            name: name,
            startTimestamp: date
        )
    }
}
