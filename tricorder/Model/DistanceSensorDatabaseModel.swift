//
//  DistanceSensorDatabaseModel.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData

@Model
class DistanceSensorDatabaseModel {
    var recordingId: PersistentIdentifier
    var batch: DistanceValue

    init(recordingId: PersistentIdentifier, batch: DistanceValue) {
        self.recordingId = recordingId
        self.batch = batch
    }
}
