//
//  HighFrequencyMotionManager.swift
//
//  Created by Julian Visser on 10.12.2024.
//

@preconcurrency import CoreMotion
import Foundation
import OSLog

actor HighFrequencyMotionManager: MotionManager {
    let manager = CMBatchedSensorManager()
    let handleUpdate: @Sendable (_ sensor: Sensor) -> Void

    init(handleUpdate: @escaping @Sendable (_: Sensor) -> Void) {
        self.handleUpdate = handleUpdate
    }
}
extension HighFrequencyMotionManager {
    nonisolated func stopUpdates() async {
        await manager.stopAccelerometerUpdates()
        await manager.stopDeviceMotionUpdates()
    }

    nonisolated func startUpdates(recordingStart: Date) async throws {
        await manager.startAccelerometerUpdates(handler: {
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

        await manager.startDeviceMotionUpdates(handler: {
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
}
