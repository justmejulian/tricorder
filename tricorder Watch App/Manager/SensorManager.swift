//
//  MotionManager.swift
//  tricorder Watch App
//
//  Created by Julian Visser on 27.10.2024.
//

import CoreMotion
import Foundation
import os

actor SensorManager {
    let eventManager = EventManager.shared

    let motionManager = CMBatchedSensorManager()
}

extension SensorManager {
    private func handleUpdate(
        _ timestamp: Date,
        _ sensor_id: String,
        _ values: [MotionValue]
    ) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")
        Task {
            await eventManager.trigger(
                key: .collectedMotionValues,
                data: values
            ) as Void
        }
    }
}

extension SensorManager {
    func stopUpdates() {
        Logger.shared.debug("MotinManager: stopUpdates called on Thread \(Thread.current)")

        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
    }

    func startUpdates() throws {
        Logger.shared.debug("MotinManager: startUpdates called on Thread \(Thread.current)")

        guard
            CMBatchedSensorManager.isAccelerometerSupported
                && CMBatchedSensorManager.isDeviceMotionSupported
        else {
            throw SensorManagerError.notSupported
        }

        motionManager.startAccelerometerUpdates(handler: {
            (batchedData, error) in

            Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

            if let error = error {
                Logger.shared.error(
                    "Error starting AccelerometerUpdates: \(error.localizedDescription)"
                )
                return
            }

            guard let batchedData = batchedData else {
                Logger.shared.error(
                    "Error starting AccelerometerUpdates: did not recive any data"
                )
                return
            }
            self.consumeAccelerometerUpdates(batchedData: batchedData)
        })

        motionManager.startDeviceMotionUpdates(handler: {
            (batchedData, error) in

            Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

            if let error = error {
                Logger.shared.error(
                    "Error starting DeviceMotionUpdate: \(error.localizedDescription)"
                )
                return
            }

            guard let batchedData = batchedData else {
                Logger.shared.error(
                    "Error starting DeviceMotionUpdate: did not recive any data"
                )
                return
            }
            self.consumeDeviceMotionUpdates(batchedData: batchedData)
        })
    }
}

// todo do this in another Manager
extension SensorManager {
    func consumeDeviceMotionUpdates(batchedData: [CMDeviceMotion]) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        // todo make this more reusable
        // todo do all of this in a different thread
        var rotationRateValues: [MotionValue] = []
        var userAccelerationValues: [MotionValue] = []
        var gravityValues: [MotionValue] = []
        var quaternionValues: [MotionValue] = []

        batchedData.forEach { data in
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

        let firstValue = rotationRateValues.first!

        let date = Date(
            timeIntervalSince1970: firstValue.timestamp.timeIntervalSince1970
        )

        // todo store these keys in enum
        handleUpdate(date, "rotationRate", rotationRateValues)

        handleUpdate(date, "userAcceleration", userAccelerationValues)

        handleUpdate(date, "gravity", gravityValues)

        handleUpdate(date, "quaternion", quaternionValues)
    }

    func consumeAccelerometerUpdates(batchedData: [CMAccelerometerData]) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        var values: [MotionValue] = []

        batchedData.forEach { data in
            values.append(
                MotionValue(
                    x: data.acceleration.x,
                    y: data.acceleration.y,
                    z: data.acceleration.z,
                    timestamp: Date(
                        timeIntervalSince1970: data.timestamp
                            .timeIntervalSince1970
                    )
                )
            )
        }

        // all have differnt timestamps
        // use first as batch tiemstamp
        // The timestamp is the amount of time in seconds since the device booted.
        let firstValue = values.first!

        let date = Date(
            timeIntervalSince1970: firstValue.timestamp.timeIntervalSince1970
        )
        handleUpdate(date, "acceleration", values)
    }
}

// MARK: - MotionManagerError
//
enum SensorManagerError: Error {
    case notSupported
}
