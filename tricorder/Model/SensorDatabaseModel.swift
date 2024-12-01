//
//  SensorDatabaseModel.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData

@Model
class SensorDatabaseModel {
    var sensorName: String
    var recordingStart: Date
    var data: Data

    init(sensorName: String, recordingStart: Date, data: Data) {
        self.sensorName = sensorName
        self.recordingStart = recordingStart
        self.data = data
    }
}

extension SensorDatabaseModel {
    // Used to pass around
    struct Struct {
        let sensorName: String
        let recordingStart: Date
        let data: Data

        init(sensor: SensorDatabaseModel) {
            self.sensorName = sensor.sensorName
            self.recordingStart = sensor.recordingStart
            self.data = sensor.data
        }
    }

    func toStruct() -> Struct {
        return Struct(sensor: self)
    }
}
