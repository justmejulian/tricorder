//
//  MotionSensorDatabaseModel.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData

protocol MotionSensorDatabaseModel {
    var recordingId: PersistentIdentifier { get set }
    var values: [MotionValue] { get set }
}

@Model
class rotationSensorDatabaseModel: MotionSensorDatabaseModel {
    var recordingId: PersistentIdentifier
    var values: [MotionValue]

    init(recordingId: PersistentIdentifier, values: [MotionValue]) {
        self.recordingId = recordingId
        self.values = values
    }
}
