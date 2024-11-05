//
//  MotionManager.swift
//  tricorder Watch App
//
//  Created by Julian Visser on 27.10.2024.
//

import CoreMotion
import Foundation
import os

actor MotionManager {
    let eventManager = EventManager.shared

    let motionManager = CMBatchedSensorManager()

    // todo should this be observable?
}
extension MotionManager {
    private func handleUpdate(
        _ timestamp: Date,
        _ sensor_id: String,
        _ values: [Value]
    ) {
        // todo: hanlde updates
        //        Logger.shared.debug(
        //            "Handle motion update: \(timestamp), \(sensor_id), \(values.debugDescription)"
        //        )
    }
}

extension MotionManager {
    func stopUpdates() {
        Logger.shared.debug("MotinManager: stopUpdates called")

        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
    }

    func startUpdates() throws {
        Logger.shared.debug("MotinManager: startUpdates called")

        guard
            CMBatchedSensorManager.isAccelerometerSupported
                && CMBatchedSensorManager.isDeviceMotionSupported
        else {
            throw MotionManagerError.notSupported
        }

        motionManager.startAccelerometerUpdates(handler: {
            (batchedData, error) in
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

    func consumeDeviceMotionUpdates(batchedData: [CMDeviceMotion]) {
        Logger.shared.debug("DeviceMotionUpdate")

        // todo make this more reusable
        // todo do all of this in a different thread
        var rotationRateValues: [Value] = []
        var userAccelerationValues: [Value] = []
        var gravityValues: [Value] = []
        var quaternionValues: [Value] = []

        batchedData.forEach { data in
            let dataDate = Date(
                timeIntervalSince1970: data.timestamp.timeIntervalSince1970
            )
            rotationRateValues.append(
                Value(
                    x: data.rotationRate.x,
                    y: data.rotationRate.y,
                    z: data.rotationRate.z,
                    timestamp: dataDate
                )
            )
            userAccelerationValues.append(
                Value(
                    x: data.userAcceleration.x,
                    y: data.userAcceleration.y,
                    z: data.userAcceleration.z,
                    timestamp: dataDate
                )
            )
            gravityValues.append(
                Value(
                    x: data.gravity.x,
                    y: data.gravity.y,
                    z: data.gravity.z,
                    timestamp: dataDate
                )
            )
            quaternionValues.append(
                Value(
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
        Logger.shared.debug("AccelerometerUpdate")
        var values: [Value] = []

        batchedData.forEach { data in
            values.append(
                Value(
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
enum MotionManagerError: Error {
    case notSupported
}

// MARK: - Value
//
extension MotionManager {
    // LogItem
    // todo: CMAcceleration or CMRotationRate CMQuaternion
    // LogItem with timestamp

    struct Value: Codable {
        var x: Double
        var y: Double
        var z: Double
        var w: Double?

        var timestamp: Date

        // Values may have 3 or 4 Datapoints
        init(x: Double, y: Double, z: Double, timestamp: Date) {
            self.x = x
            self.y = y
            self.z = z
            self.w = nil
            self.timestamp = timestamp
        }

        init(x: Double, y: Double, z: Double, w: Double, timestamp: Date) {
            self.x = x
            self.y = y
            self.z = z
            self.w = w
            self.timestamp = timestamp
        }
    }

}
