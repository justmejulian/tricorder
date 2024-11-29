//
//  SensorDatabaseModel.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData

@Model
class SensorDatabaseModel {
    var sensorName: SensorName
    var recordingStart: Date
    var data: Data

    init(sensorName: SensorName, recordingStart: Date, data: Data) {
        self.sensorName = sensorName
        self.recordingStart = recordingStart
        self.data = data
    }
}

extension SensorDatabaseModel {
    enum SensorName: String, Codable {
        case acceleration
        case rotationRate
        case userAcceleration
        case gravity
        case quaternion
        case heartRate
        case distance
    }
}
