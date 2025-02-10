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

    init(
        handleUpdate: @escaping @Sendable (_: Sensor) -> Void
    ) {
        self.handleUpdate = handleUpdate
    }
}
extension HighFrequencyMotionManager {
    nonisolated func stopUpdates() async {
        await manager.stopAccelerometerUpdates()
        await manager.stopDeviceMotionUpdates()
    }

    nonisolated func startUpdates(
        recordingStart: Date,
        motionSensors: [Sensor.MotionSensorName: Bool]?
    ) async throws {
        if CMBatchedSensorManager.authorizationStatus == .denied {
            Logger.shared.error("CMBatchedSensorManager authorizationStatus is denied")
            throw HighFrequencyMotionManagerError.notSupported
        }
        if CMBatchedSensorManager.authorizationStatus == .restricted {
            Logger.shared.error("CMBatchedSensorManager authorizationStatus is restricted")
            throw HighFrequencyMotionManagerError.notSupported
        }

        guard
            CMBatchedSensorManager.isAccelerometerSupported
                && CMBatchedSensorManager.isDeviceMotionSupported
        else {
            throw HighFrequencyMotionManagerError.notSupported
        }

        let motionSensors = motionSensors ?? [:]

        if motionSensors[.acceleration] ?? true {
            await manager.startAccelerometerUpdates(handler: {
                @Sendable (data, error) in
                if let error = error {
                    Logger.shared.error(
                        "Error starting AccelerometerUpdates: \(error.localizedDescription)"
                    )
                    return
                }

                guard let data = data else {
                    Logger.shared.error(
                        "Error starting AccelerometerUpdates: did not recive any data"
                    )
                    return
                }

                self.consumeAccelerometerUpdates(
                    dataArray: data,
                    recordingStart: recordingStart
                )
            })
        }

        await manager.startDeviceMotionUpdates(handler: {
            @Sendable (data, error) in

            if let error = error {
                Logger.shared.error(
                    "Error starting DeviceMotionUpdate: \(error.localizedDescription)"
                )
                return
            }

            guard let data = data else {
                Logger.shared.error(
                    "Error starting DeviceMotionUpdate: did not recive any data"
                )
                return
            }

            self.consumeDeviceMotionUpdates(
                dataArray: data,
                recordingStart: recordingStart,
                motionSensors: motionSensors
            )
        })
    }

    nonisolated func consumeAccelerometerUpdates(
        dataArray: [CMAccelerometerData],
        recordingStart: Date
    ) {

        var values: [MotionValue] = []

        // todo replace with reduce
        dataArray.forEach { data in
            values.append(createMotionValues(data: data))
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
        dataArray: [CMDeviceMotion],
        recordingStart: Date,
        motionSensors: [Sensor.MotionSensorName: Bool]
    ) {

        var values: [Sensor.MotionSensorName: [MotionValue]] = [:]

        dataArray.forEach { data in
            let motionValues = createMotionValues(
                data: data,
                motionSensors: motionSensors
            )

            for motionValue in motionValues {
                if values[motionValue.key] == nil {
                    values[motionValue.key] = []
                }

                values[motionValue.key]?.append(motionValue.value)
            }
        }

        for value in values {
            handleUpdate(
                Sensor.motion(
                    value.key,
                    recordingStartDate: recordingStart,
                    values: value.value
                )
            )
        }
    }
}

enum HighFrequencyMotionManagerError: LocalizedError {
    case notSupported

    var errorDescription: String? {
        switch self {
        case .notSupported:
            return
                "High-frequency motion tracking is not supported on this device. Make sure to enable Motion Permissions."
        }
    }
}
