//
//  SensorDatabaseModel.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData

@Model
final public class SensorDatabaseModel {
    var recordingStart: Date
    var sensorJson: Data

    var sensor: Sensor {
        do {
            return try JSONDecoder().decode(Sensor.self, from: sensorJson)
        } catch {
            fatalError("Could not decode Sensor from JSON: \(error)")
        }
    }

    init(recordingStart: Date, sensorJson: Data) {
        self.recordingStart = recordingStart
        self.sensorJson = sensorJson
    }

    init(recordingStart: Date, sensor: Sensor) throws {
        self.recordingStart = recordingStart
        self.sensorJson = try JSONEncoder().encode(sensor)
    }
}
