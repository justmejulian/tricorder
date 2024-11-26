//
//  MotionSensorDatabaseModel.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData

@Model
class MotionSensorBatchDatabaseModel {
    var recordingId: PersistentIdentifier
    var sensorName: MotionSensor.SensorName
    var values: [MotionValue]

    init(
        recordingId: PersistentIdentifier,
        sensorName: MotionSensor.SensorName,
        values: [MotionValue]
    ) {
        self.recordingId = recordingId
        self.sensorName = sensorName
        self.values = values
    }
}
