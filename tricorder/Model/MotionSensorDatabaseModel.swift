//
//  MotionSensorDatabaseModel.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData

@Model
class MotionSensorDatabaseModel {
    var recordingStart: Date
    var sensorName: SensorName
    var batch: [MotionValue]

    init(
        recordingStart: Date,
        sensorName: SensorName,
        batch: [MotionValue]
    ) {
        self.recordingStart = recordingStart
        self.sensorName = sensorName
        self.batch = batch
    }
}
