//
//  MotionManager.swift
//
//  Created by Julian Visser on 10.12.2024.
//

@preconcurrency import CoreMotion
import Foundation
import OSLog

protocol MotionManager: Actor {
    func startUpdates(
        recordingStart: Date,
        motionSensors: [Sensor.MotionSensorName: Bool]?
    ) async throws
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
        data: CMDeviceMotion,
        motionSensors: [Sensor.MotionSensorName: Bool]
    ) -> [Sensor.MotionSensorName: MotionValue] {
        let dataDate = getDateFromTimestamp(data.timestamp)

        if motionSensors.isEmpty {
            return PotentialCMDeviceMotion.allCases
                .reduce(into: [:]) { result, sensor in
                    result[sensor.sensorName] = sensor.generateMotionValue(
                        from: data,
                        timestamp: dataDate
                    )
                }
        }

        return PotentialCMDeviceMotion.allCases
            .filter { motionSensors[$0.sensorName] ?? true }
            .reduce(into: [:]) { result, sensor in
                result[sensor.sensorName] = sensor.generateMotionValue(
                    from: data,
                    timestamp: dataDate
                )
            }
    }
}

enum PotentialCMDeviceMotion: CaseIterable {
    case rotationRate
    case userAcceleration
    case gravity
    case quaternion

    var sensorName: Sensor.MotionSensorName {
        switch self {
        case .rotationRate: return .rotationRate
        case .userAcceleration: return .userAcceleration
        case .gravity: return .gravity
        case .quaternion: return .quaternion
        }
    }

    func generateMotionValue(from data: CMDeviceMotion, timestamp: Date) -> MotionValue {
        switch self {
        case .rotationRate:
            return MotionValue(
                x: data.rotationRate.x,
                y: data.rotationRate.y,
                z: data.rotationRate.z,
                timestamp: timestamp
            )
        case .userAcceleration:
            return MotionValue(
                x: data.userAcceleration.x,
                y: data.userAcceleration.y,
                z: data.userAcceleration.z,
                timestamp: timestamp
            )
        case .gravity:
            return MotionValue(
                x: data.gravity.x,
                y: data.gravity.y,
                z: data.gravity.z,
                timestamp: timestamp
            )
        case .quaternion:
            return MotionValue(
                x: data.attitude.quaternion.x,
                y: data.attitude.quaternion.y,
                z: data.attitude.quaternion.z,
                w: data.attitude.quaternion.w,
                timestamp: timestamp
            )
        }
    }

}
