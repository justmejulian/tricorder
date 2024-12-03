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

    let motionManager = CMBatchedSensorManager()
}

extension CoreMotionManager {
    func stopUpdates() {
        Logger.shared.debug("MotinManager: stopUpdates called on Thread \(Thread.current)")

        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
    }

    func startUpdates(recordingStart: Date) throws {
        Logger.shared.debug("MotinManager: startUpdates called on Thread \(Thread.current)")

        guard
            CMBatchedSensorManager.isAccelerometerSupported
                && CMBatchedSensorManager.isDeviceMotionSupported
        else {
            throw CoreMotionManagerError.notSupported
        }

        motionManager.startAccelerometerUpdates(handler: {
            @Sendable (valuesedData, error) in

            Logger.shared.debug("called on Thread \(Thread.current)")

            if let error = error {
                Logger.shared.error(
                    "Error starting AccelerometerUpdates: \(error.localizedDescription)"
                )
                return
            }

            guard let valuesedData = valuesedData else {
                Logger.shared.error(
                    "Error starting AccelerometerUpdates: did not recive any data"
                )
                return
            }
            self.consumeAccelerometerUpdates(
                valuesedData: valuesedData,
                recordingStart: recordingStart
            )
        })

        motionManager.startDeviceMotionUpdates(handler: {
            @Sendable (valuesedData, error) in

            Logger.shared.debug("called on Thread \(Thread.current)")

            if let error = error {
                Logger.shared.error(
                    "Error starting DeviceMotionUpdate: \(error.localizedDescription)"
                )
                return
            }

            guard let valuesedData = valuesedData else {
                Logger.shared.error(
                    "Error starting DeviceMotionUpdate: did not recive any data"
                )
                return
            }
            self.consumeDeviceMotionUpdates(
                valuesedData: valuesedData,
                recordingStart: recordingStart
            )
        })
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

    nonisolated func consumeDeviceMotionUpdates(
        valuesedData: [CMDeviceMotion],
        recordingStart: Date
    ) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        // todo make this more reusable
        // todo do all of this in a different thread
        var rotationRateValues: [MotionValue] = []
        var userAccelerationValues: [MotionValue] = []
        var gravityValues: [MotionValue] = []
        var quaternionValues: [MotionValue] = []

        valuesedData.forEach { data in
            let dataDate = Date(
                timeIntervalSince1970: data.timestamp.timeIntervalSince1970
            )
            rotationRateValues.append(
                MotionValue(
                    x: data.rotationRate.x,
                    y: data.rotationRate.y,
                    z: data.rotationRate.z,
                    timestamp: dataDate
                )
            )
            userAccelerationValues.append(
                MotionValue(
                    x: data.userAcceleration.x,
                    y: data.userAcceleration.y,
                    z: data.userAcceleration.z,
                    timestamp: dataDate
                )
            )
            gravityValues.append(
                MotionValue(
                    x: data.gravity.x,
                    y: data.gravity.y,
                    z: data.gravity.z,
                    timestamp: dataDate
                )
            )
            quaternionValues.append(
                MotionValue(
                    x: data.attitude.quaternion.x,
                    y: data.attitude.quaternion.y,
                    z: data.attitude.quaternion.z,
                    w: data.attitude.quaternion.w,
                    timestamp: dataDate
                )
            )
        }

        handleUpdate(
            Sensor.motion(
                .rotationRate,
                recordingStartDate: recordingStart,
                values: rotationRateValues
            )
        )
        handleUpdate(
            Sensor.motion(
                .userAcceleration,
                recordingStartDate: recordingStart,
                values: userAccelerationValues
            )
        )
        handleUpdate(
            Sensor.motion(
                .gravity,
                recordingStartDate: recordingStart,
                values: gravityValues
            )
        )
        handleUpdate(
            Sensor.motion(
                .quaternion,
                recordingStartDate: recordingStart,
                values: quaternionValues
            )
        )
    }

    nonisolated func consumeAccelerometerUpdates(
        valuesedData: [CMAccelerometerData],
        recordingStart: Date
    ) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        var values: [MotionValue] = []

        valuesedData.forEach { data in
            values.append(
                MotionValue(
                    x: data.acceleration.x,
                    y: data.acceleration.y,
                    z: data.acceleration.z,

                    // The timestamp is the amount of time in seconds since the device booted.
                    timestamp: Date(
                        timeIntervalSince1970: data.timestamp
                            .timeIntervalSince1970
                    )
                )
            )
        }
        handleUpdate(
            Sensor.motion(
                .acceleration,
                recordingStartDate: recordingStart,
                values: values
            )
        )
    }
}

// MARK: - MotionManagerError
//
enum CoreMotionManagerError: Error {
    case notSupported
}
