//
//  HeartRateSensorDatabaseModel.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData

@Model
class HeartRateSensorBatchDatabaseModel {
    var recordingId: PersistentIdentifier
    var value: HeartRateValue

    init(recordingId: PersistentIdentifier, value: HeartRateValue) {
        self.recordingId = recordingId
        self.value = value
    }
}
