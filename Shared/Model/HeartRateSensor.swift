//
//  HeartRateSensor.swift
//
//  Created by Julian Visser on 23.11.2024.
//

import Foundation

struct HeartRateSensor: Sensor {
    let recordingStart: Date
    var values: [HeartRateValue]

    init(recordingStart: Date, values: [HeartRateValue]) {
        self.recordingStart = recordingStart
        self.values = values
    }
}
