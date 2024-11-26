//
//  MotionSensorDatabaseModel.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData

@Model
class MotionSensorDatabaseModel {
    var recordingId: PersistentIdentifier
    var sensorName: SensorName
    var batch: [MotionValue]

    init(
        recordingId: PersistentIdentifier,
        sensorName: SensorName,
        batch: [MotionValue]
    ) {
        self.recordingId = recordingId
        self.sensorName = sensorName
        self.batch = batch
    }
}
