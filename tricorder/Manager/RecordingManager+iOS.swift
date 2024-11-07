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
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        await eventManager.register(
            key: .sessionStateChanged,
            handleData: self.handleSessionStateChange
        )

        await eventManager.register(
            key: .receivedData,
            handleData: self.handleReceivedData
        )
    }

    func resetRest() {

    }
}

// MARK: -  RecordingManager functions
//
extension RecordingManager {
    func startRecording() async {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")
        do {
            try await workoutManager.startWatchWorkout()
        } catch {
            Logger.shared.log(
                "Failed to start cycling on the paired watch."
            )
        }
    }

    func stopRecording() async {
        await workoutManager.session?.stopActivity(with: .now)
    }
}

extension RecordingManager {
    @Sendable
    nonisolated func handleSessionStateChange(_ data: Sendable) throws {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        guard let change = data as? SessionStateChange else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        Logger.shared.info(
            "Session state changed to \(change.newState.rawValue)"
        )

        Task {
            await setRecordingState(newState: change.newState)
        }
    }

    @Sendable
    nonisolated func handleReceivedData(_ data: Sendable) throws {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        guard let data = data as? Data else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        let dataObject = try SendDataObjectManager().decode(data)

        // todo move these keys into and enum, so I know what is possible

        switch dataObject.key {
        case "startDate":
            if let startDate = try? JSONDecoder().decode(
                Date.self,
                from: dataObject.data
            ) {
                Logger.shared.info("Recieved startDate: \(startDate)")

                Task {
                    await setStartDate(startDate)
                }
            }
        case "statistics":
            if let statistics =
                try NSKeyedUnarchiver.unarchivedObject(
                    ofClass: HKStatistics.self,
                    from: dataObject.data
                )
            {
                Logger.shared.info(
                    "statistics: \(statistics.debugDescription)"
                )

                Task {
                    await statisticsManager.updateForStatistics(statistics)
                }
            }
        case "discoveryToken":
            Task {
                await handleNIReceiveDiscoveryToken(dataObject.data)
            }

        case "motionUpdate":
            guard let values = try? JSONDecoder().decode([MotionValue].self, from: dataObject.data)
            else {
                Logger.shared.error("\(#function): Invalid data type")
                return
            }
            Task {
                await motionManager.updateMotionValues(values)
            }

        default:
            Logger.shared.error("unknown dataObject key: \(dataObject.key)")
        }

    }
}
