//
//  DistanceSensor.swift
//
//  Created by Julian Visser on 23.11.2024.
//

import Foundation

struct DistanceSensor: Sensor {
    let recordingStart: Date
    var batch: [DistanceValue]

    init(recordingStart: Date, batch: [DistanceValue]) {
        self.recordingStart = recordingStart
        self.batch = batch
    }
}
