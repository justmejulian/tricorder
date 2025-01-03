//
//  LowFrequencyMotionManager.swift
//
//  Created by Julian Visser on 10.12.2024.
//

@preconcurrency import CoreMotion
import Foundation
import OSLog

actor LowFrequencyMotionManager: MotionManager {
    let manager = CMMotionManager()
    let queue = OperationQueue()

    let handleUpdate: @Sendable (_ sensor: Sensor) -> Void

    init(
        handleUpdate: @escaping @Sendable (_: Sensor) -> Void
    ) {
        self.handleUpdate = handleUpdate
    }

    func setAccelerometerUpdateInterval(_ rate: Int?) {
        guard let rate else {
            return
        }
        manager.accelerometerUpdateInterval = 1.0 * Double(rate)
    }

    func setDeviceMotionUpdateInterval(_ rate: Int?) {
        guard let rate else {
            return
        }
        manager.deviceMotionUpdateInterval = 1.0 * Double(rate)
    }
}
extension LowFrequencyMotionManager {
    nonisolated func stopUpdates() async {
        await manager.stopAccelerometerUpdates()
        await manager.stopDeviceMotionUpdates()
    }

    nonisolated func startUpdates(
        recordingStart: Date,
        motionSensors: [Sensor.MotionSensorName: Bool]?
    ) async throws {
        try await startUpdates(
            recordingStart: recordingStart,
            motionSensors: motionSensors ?? [:],
            accelerometerRecordingRate: 200,
            deviceMotionRecordingRate: 200
        )
    }

    nonisolated func startUpdates(
        recordingStart: Date,
        motionSensors: [Sensor.MotionSensorName: Bool],
        accelerometerRecordingRate: Int?,
        deviceMotionRecordingRate: Int?
    ) async throws {

        guard
            await manager.isDeviceMotionAvailable
        else {
            throw HighFrequencyMotionManagerError.notSupported
        }

        if let accelerometerRecordingRate = accelerometerRecordingRate {
            await setAccelerometerUpdateInterval(accelerometerRecordingRate)
        }

        if let deviceMotionRecordingRate = deviceMotionRecordingRate {
            await setDeviceMotionUpdateInterval(deviceMotionRecordingRate)
        }

        if motionSensors[.acceleration] ?? true {
            await manager.startAccelerometerUpdates(
                to: self.queue,
                withHandler: {
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
                        data: data,
                        recordingStart: recordingStart
                    )
                }
            )
        }

        await manager.startDeviceMotionUpdates(
            to: self.queue,
            withHandler: {
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
                    data: data,
                    recordingStart: recordingStart,
                    motionSensors: motionSensors
                )
            }
        )
    }

    nonisolated func consumeAccelerometerUpdates(
        data: CMAccelerometerData,
        recordingStart: Date
    ) {

        handleUpdate(
            Sensor.motion(
                .acceleration,
                recordingStartDate: recordingStart,
                values: [
                    createMotionValues(data: data)
                ]
            )
        )
    }
    nonisolated func consumeDeviceMotionUpdates(
        data: CMDeviceMotion,
        recordingStart: Date,
        motionSensors: [Sensor.MotionSensorName: Bool]
    ) {

        let motionValues = createMotionValues(
            data: data,
            motionSensors: motionSensors
        )

        for motionValue in motionValues {
            handleUpdate(
                Sensor.motion(
                    motionValue.key,
                    recordingStartDate: recordingStart,
                    values: [motionValue.value]
                )
            )
        }

    }
}
