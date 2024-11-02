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
        await eventManager.register(
            key: .sessionStateChanged, handleData: self.handleSessionStateChange
        )

        await eventManager.register(
            key: .receivedData, handleData: self.handleReceivedData
        )
    }

    func resetRest() {
        
    }
}

// MARK: -  RecordingManager functions
//
extension RecordingManager {
    func startRecording() async {
        do {
            try await workoutManager.startWatchWorkout()
        } catch {
            Logger.shared.log(
                "Failed to start cycling on the paired watch.")
        }
    }

    func stopRecording() async {
        workoutManager.session?.stopActivity(with: .now)
    }
}

extension RecordingManager {
    @Sendable
    nonisolated func handleSessionStateChange(_ data: Sendable) throws {
        Logger.shared.info("\(#function)")

        guard let change = data as? SessionStateChange else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        Logger.shared.info(
            "Session state changed to \(change.newState.rawValue)")

        Task {
            await setRecordingState(newState: change.newState)
        }
    }

    @Sendable
    nonisolated func handleReceivedData(_ data: Sendable) throws {
        Logger.shared.info("\(#function) called")

        guard let data = data as? Data else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        let dataObject = try DataObjectManager().decode(data)

        // todo move these keys into and enum, so I know what is possible

        switch dataObject.key {
        case "elapsedTime":
            if let elapsedTime = try? JSONDecoder().decode(
                WorkoutElapsedTime.self, from: dataObject.data)
            {
                Logger.shared.info("elapsedTime: \(elapsedTime.timeInterval)")

                Task {
                    await setElapsedTimeInterval(elapsedTime: elapsedTime)
                }
            }
        case "statisticsArray":
            if let statisticsArray =
                try NSKeyedUnarchiver.unarchivedArrayOfObjects(
                    ofClass: HKStatistics.self, from: dataObject.data)
            {
                Logger.shared.info(
                    "statisticsArray: \(statisticsArray.debugDescription)")

                Task {
                    for statistics in statisticsArray {
                        let mostRecentStatistic = await statisticsManager.updateForStatistics(statistics)
                        
                        let newHeartRate = mostRecentStatistic[.heartRate] ?? 0
                        await setHeartRate(heartRate: newHeartRate)
                    }
                }
            }

        case "discoveryToken":
            Task {
                await handleNIReceiveDiscoveryToken(dataObject.data)
            }

        default:
            Logger.shared.error("unknown dataObject key: \(dataObject.key)")
        }

    }
}
