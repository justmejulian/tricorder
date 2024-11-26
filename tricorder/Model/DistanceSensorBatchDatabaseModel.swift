//
//  DistanceSensorBatchDatabaseModel.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData

@Model
class DistanceSensorBatchDatabaseModel {
    var recordingId: PersistentIdentifier
    var value: DistanceValue

    init(recordingId: PersistentIdentifier, value: DistanceValue) {
        self.recordingId = recordingId
        self.value = value
    }
}
