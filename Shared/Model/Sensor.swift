//
//  Sensor.swift
//
//  Created by Julian Visser on 29.11.2024.
//

enum Sensor: Codable {
    case motion(MotionSensorName, batch: [MotionValue])
    case statistic(StatisticSensorName, batch: [StatisticValue])
    case distance(DistanceSensorName, batch: [DistanceValue])

    private enum CodingKeys: String, CodingKey {
        case type
        case name
        case batch
    }

    private enum SensorType: String, Codable {
        case motion
        case statistic
        case distance
    }

    // Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(SensorType.self, forKey: .type)

        switch type {
        case .motion:
            let name = try container.decode(MotionSensorName.self, forKey: .name)
            let batch = try container.decode([MotionValue].self, forKey: .batch)
            self = .motion(name, batch: batch)
        case .statistic:
            let name = try container.decode(StatisticSensorName.self, forKey: .name)
            let batch = try container.decode([StatisticValue].self, forKey: .batch)
            self = .statistic(name, batch: batch)
        case .distance:
            let name = try container.decode(DistanceSensorName.self, forKey: .name)
            let batch = try container.decode([DistanceValue].self, forKey: .batch)
            self = .distance(name, batch: batch)
        }
    }

    // Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .motion(let name, let batch):
            try container.encode(SensorType.motion, forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(batch, forKey: .batch)
        case .statistic(let name, let batch):
            try container.encode(SensorType.statistic, forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(batch, forKey: .batch)
        case .distance(let name, let batch):
            try container.encode(SensorType.distance, forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(batch, forKey: .batch)
        }
    }

    func chunked(into size: Int) throws -> [Sensor] {
        switch self {
        case .motion(let name, let batch):
            if batch.count < size {
                return [self]
            }

            let chunks = batch.chunked(into: size)
            return chunks.map {
                return Sensor.motion(name, batch: $0)
            }
        case .statistic(let name, let batch):
            if batch.count < size {
                return [self]
            }

            let chunks = batch.chunked(into: size)
            return chunks.map {
                return Sensor.statistic(name, batch: $0)
            }
        case .distance(let name, let batch):
            if batch.count < size {
                return [self]
            }

            let chunks = batch.chunked(into: size)
            return chunks.map {
                return Sensor.distance(name, batch: $0)
            }
        }

    }
}

enum MotionSensorName: String, Codable {
    case acceleration
    case rotationRate
    case userAcceleration
    case gravity
    case quaternion
}

enum StatisticSensorName: String, Codable {
    case heartRate
}

enum DistanceSensorName: String, Codable {
    case distance
}
