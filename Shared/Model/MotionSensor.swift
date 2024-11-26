//
//  MotionSensor.swift
//
//  Created by Julian Visser on 23.11.2024.
//

import Foundation

struct MotionSensor: Sensor {
    let sensorName: SensorName
    let recordingStart: Date
    var batch: [MotionValue]
}
extension MotionSensor {
    enum SensorName: String, Codable {
        case acceleration
        case rotationRate
        case userAcceleration
        case gravity
        case quaternion
    }
}

extension MotionSensor {
    func chunked(into size: Int) throws -> [MotionSensor] {
        if batch.count < size {
            return [self]
        }

        let chunks = batch.chunked(into: size)

        return chunks.map {
            return MotionSensor(
                sensorName: sensorName,
                recordingStart: recordingStart,
                batch: $0
            )
        }

    }
}
