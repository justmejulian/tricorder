//
//  MotionManager.swift
//  tricorder Watch App
//
//  Created by Julian Visser on 27.10.2024.
//

import CoreMotion
import Foundation
import OSLog

actor CoreMotionManager {
    let eventManager = EventManager.shared

    var motionManager: MotionManager? = nil
}

extension CoreMotionManager {
    func stopUpdates() async {
        Logger.shared.debug("MotinManager: stopUpdates called on Thread \(Thread.current)")

        guard let motionManager else {
            Logger.shared.error("Tried to stop updates but motionManager is nil")
            return
        }

        await motionManager.stopUpdates()

        self.motionManager = nil
    }

    func startUpdates(recordingStart: Date, settings: Settings?) async throws {
        Logger.shared.debug("MotinManager: startUpdates called on Thread \(Thread.current)")

        var motionManager: MotionManager {
            guard let settings else {
                return HighFrequencyMotionManager(handleUpdate: handleUpdate)
            }

            if settings.useHighFrequencySensor {
                return HighFrequencyMotionManager(handleUpdate: handleUpdate)
            }

            return LowFrequencyMotionManager(handleUpdate: handleUpdate)
        }

        try await motionManager.startUpdates(
            recordingStart: recordingStart,
            motionSensors: settings?.motionSensors
        )

        self.motionManager = motionManager
    }
}

// MARK: - nonisolated
//
extension CoreMotionManager {
    nonisolated private func handleUpdate(
        _ sensor: Sensor
    ) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        Task {
            await eventManager.trigger(
                key: .collectedSensorValues,
                data: sensor
            ) as Void
        }
    }
}

// MARK: - MotionManagerError
//
enum CoreMotionManagerError: Error {
    case notSupported
}
