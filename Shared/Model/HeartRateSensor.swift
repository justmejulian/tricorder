//
//  HeartRateSensor.swift
//
//  Created by Julian Visser on 23.11.2024.
//

import Foundation

struct HeartRateSensor: Sensor {
    let recordingStart: Date
    var batch: [HeartRateValue]

    init(recordingStart: Date, batch: [HeartRateValue]) {
        self.recordingStart = recordingStart
        self.batch = batch
    }
}
