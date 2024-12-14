//
//  MotionManager.swift
//
//  Created by Julian Visser on 10.12.2024.
//

@preconcurrency import CoreMotion
import Foundation
import OSLog

protocol MotionManager: Actor {
    func startUpdates(recordingStart: Date) async throws
    func stopUpdates() async
    var handleUpdate: @Sendable (_ sensor: Sensor) -> Void { get }
}

extension MotionManager {
    nonisolated private func getDateFromTimestamp(
        _ timestamp: TimeInterval
    ) -> Date {
        // The timestamp is the amount of time in seconds since the device booted.
        return Date(
            timeIntervalSince1970: timestamp.timeIntervalSince1970
        )
    }

    nonisolated func createMotionValues(
        data: CMAccelerometerData
    ) -> MotionValue {
        let dataDate = getDateFromTimestamp(data.timestamp)
        return MotionValue(
            x: data.acceleration.x,
            y: data.acceleration.y,
            z: data.acceleration.z,
            timestamp: dataDate
        )
    }
    nonisolated func createMotionValues(
        data: CMDeviceMotion
    ) -> [Sensor.MotionSensorName: MotionValue] {
        let dataDate = getDateFromTimestamp(data.timestamp)
        return [
            .rotationRate: MotionValue(
                x: data.rotationRate.x,
                y: data.rotationRate.y,
                z: data.rotationRate.z,
                timestamp: dataDate
            ),
            .userAcceleration: MotionValue(
                x: data.userAcceleration.x,
                y: data.userAcceleration.y,
                z: data.userAcceleration.z,
                timestamp: dataDate
            ),
            .gravity: MotionValue(
                x: data.gravity.x,
                y: data.gravity.y,
                z: data.gravity.z,
                timestamp: dataDate
            ),
            .quaternion: MotionValue(
                x: data.attitude.quaternion.x,
                y: data.attitude.quaternion.y,
                z: data.attitude.quaternion.z,
                w: data.attitude.quaternion.w,
                timestamp: dataDate
            ),
        ]
    }
}
