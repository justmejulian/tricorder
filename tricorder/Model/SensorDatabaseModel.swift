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
