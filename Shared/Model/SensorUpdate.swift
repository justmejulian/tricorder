//
//  SensorUpdate.swift
//
//  Created by Julian Visser on 26.11.2024.
//

enum SensorUpdate: Codable {
    case motion(MotionSensorName, values: [MotionValue])
    case statistic(StatisticSensorName, values: [StatisticValue])
    case distance(DistanceSensorName, values: [DistanceValue])
}

extension SensorUpdate {
    func getValues() -> [Value] {
        switch self {
        case .motion(let name, let values):
            return values
        case .statistic(let name, let values):
            return values
        case .distance(let name, let values):
            return values
        }
    }
}

extension SensorUpdate {
    enum SensorName: Codable {
        case motion(MotionSensorName)
        case statistic(StatisticSensorName)
        case distance(DistanceSensorName)
    }

    enum MotionSensorName: Codable {
        case acceleration
        case rotationRate
        case userAcceleration
        case gravity
        case quaternion
    }

    enum StatisticSensorName: Codable {
        case heartRate
    }

    enum DistanceSensorName: Codable {
        case distance
    }
}
