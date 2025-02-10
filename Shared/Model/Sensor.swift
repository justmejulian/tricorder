//
//  Sensor.swift
//
//  Created by Julian Visser on 29.11.2024.
//

import Foundation

enum Sensor: Codable {
    case motion(MotionSensorName, recordingStartDate: Date, values: [MotionValue])
    case statistic(StatisticSensorName, recordingStartDate: Date, values: [StatisticValue])
    case distance(DistanceSensorName, recordingStartDate: Date, values: [DistanceValue])

    var name: any SensorName {
        switch self {
        case .motion(let name, _, _):
            return name
        case .statistic(let name, _, _):
            return name
        case .distance(let name, _, _):
            return name
        }
    }

    var recordingStartDate: Date {
        switch self {
        case .motion(_, let date, _):
            return date
        case .statistic(_, let date, _):
            return date
        case .distance(_, let date, _):
            return date
        }
    }

    var valuesCount: Int {
        switch self {
        case .motion(_, _, let values):
            return values.count
        case .statistic(_, _, let values):
            return values.count
        case .distance(_, _, let values):
            return values.count
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case name
        case recordingStartDate
        case values
    }

    private enum SensorType: String, Codable {
        case motion
        case statistic
        case distance
    }

    protocol SensorName: Codable, CaseIterable {
        var name: String { get }
        var rawValue: String { get }
    }

    enum MotionSensorName: String, SensorName {
        case acceleration
        case rotationRate
        case userAcceleration
        case gravity
        case quaternion

        var name: String {
            switch self {
            case .acceleration:
                return "Acceleration"
            case .rotationRate:
                return "Rotation Rate"
            case .userAcceleration:
                return "User Acceleration"
            case .gravity:
                return "Gravity"
            case .quaternion:
                return "Quaternion"
            }
        }
    }

    enum StatisticSensorName: String, SensorName {
        case heartRate

        var name: String {
            switch self {
            case .heartRate:
                return "Heart Rate"
            }
        }
    }

    enum DistanceSensorName: String, SensorName {
        case distance

        var name: String {
            switch self {
            case .distance:
                return "Distance"
            }
        }
    }

    // Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(SensorType.self, forKey: .type)

        switch type {
        case .motion:
            let name = try container.decode(MotionSensorName.self, forKey: .name)
            let values = try container.decode([MotionValue].self, forKey: .values)
            let recordingStartDate = try container.decode(Date.self, forKey: .recordingStartDate)
            self = .motion(name, recordingStartDate: recordingStartDate, values: values)
        case .statistic:
            let name = try container.decode(StatisticSensorName.self, forKey: .name)
            let values = try container.decode([StatisticValue].self, forKey: .values)
            let recordingStartDate = try container.decode(Date.self, forKey: .recordingStartDate)
            self = .statistic(name, recordingStartDate: recordingStartDate, values: values)
        case .distance:
            let name = try container.decode(DistanceSensorName.self, forKey: .name)
            let values = try container.decode([DistanceValue].self, forKey: .values)
            let recordingStartDate = try container.decode(Date.self, forKey: .recordingStartDate)
            self = .distance(name, recordingStartDate: recordingStartDate, values: values)
        }
    }

    // Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .motion(let name, let recordingStartDate, let values):
            try container.encode(SensorType.motion, forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(recordingStartDate, forKey: .recordingStartDate)
            try container.encode(values, forKey: .values)
        case .statistic(let name, let recordingStartDate, let values):
            try container.encode(SensorType.statistic, forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(recordingStartDate, forKey: .recordingStartDate)
            try container.encode(values, forKey: .values)
        case .distance(let name, let recordingStartDate, let values):
            try container.encode(SensorType.distance, forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(recordingStartDate, forKey: .recordingStartDate)
            try container.encode(values, forKey: .values)
        }
    }

    // diveds a Sensor with valueses into [Sensor] with chunks of the valueses
    func chunked(into size: Int) -> [Sensor] {
        switch self {
        case .motion(let name, let recordingStartDate, let values):
            if values.count < size {
                return [self]
            }

            let chunks = values.chunked(into: size)
            return chunks.map {
                return Sensor.motion(name, recordingStartDate: recordingStartDate, values: $0)
            }

        case .statistic, .distance:
            return [self]
        }
    }
}

func mergeSensorValues(a: Sensor, b: Sensor) throws -> Sensor {
    switch (a, b) {
    case let (.motion(sensorNameA, dateA, valuesA), .motion(sensorNameB, dateB, valuesB)):
        guard sensorNameA == sensorNameB else {
            throw SensorError.differentSensors
        }
        let mergedRecordingStartDate = min(dateA, dateB)
        let mergedBatch = valuesA + valuesB
        return .motion(
            sensorNameA,
            recordingStartDate: mergedRecordingStartDate,
            values: mergedBatch
        )

    case let (.statistic(sensorNameA, dateA, valuesA), .statistic(sensorNameB, dateB, valuesB)):
        guard sensorNameA == sensorNameB else {
            throw SensorError.differentSensors
        }
        let mergedRecordingStartDate = min(dateA, dateB)
        let mergedBatch = valuesA + valuesB
        return .statistic(
            sensorNameA,
            recordingStartDate: mergedRecordingStartDate,
            values: mergedBatch
        )

    case let (.distance(sensorNameA, dateA, valuesA), .distance(sensorNameB, dateB, valuesB)):
        guard sensorNameA == sensorNameB else {
            throw SensorError.differentSensors
        }
        let mergedRecordingStartDate = min(dateA, dateB)
        let mergedBatch = valuesA + valuesB
        return .distance(
            sensorNameA,
            recordingStartDate: mergedRecordingStartDate,
            values: mergedBatch
        )

    default:
        throw SensorError.differentSensors
    }
}

func getEmpytSensorOfEach(recordingStart: Date) -> [String: Sensor] {
    let motionSensors = Sensor.MotionSensorName.allCases.map {
        Sensor.motion($0, recordingStartDate: recordingStart, values: [])
    }

    let statisticSensors = Sensor.StatisticSensorName.allCases.map {
        Sensor.statistic($0, recordingStartDate: recordingStart, values: [])
    }

    let distanceSensors = Sensor.DistanceSensorName.allCases.map {
        Sensor.distance($0, recordingStartDate: recordingStart, values: [])
    }

    let merged = motionSensors + statisticSensors + distanceSensors

    return merged.reduce(into: [:]) { result, sensor in
        result[sensor.name.rawValue] = sensor
    }
}

func getDefaultMotionsensorRecordingRate(sensorName: Sensor.MotionSensorName) -> Int {
    getMaxMotionsensorRecordingRate(sensorName: sensorName)
}

// For not hight frequency
func getMaxMotionsensorRecordingRate(sensorName: Sensor.MotionSensorName) -> Int {
    switch sensorName {
    case .acceleration, .rotationRate, .userAcceleration, .gravity, .quaternion:
        return 100
    }
}

enum SensorError: LocalizedError {
    case differentSensors

    var errorDescription: String? {
        switch self {
        case .differentSensors:
            return "The sensors provided are not compatible or do not match."
        }
    }
}
