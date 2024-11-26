//
//  DistanceSensor.swift
//
//  Created by Julian Visser on 23.11.2024.
//

import Foundation

struct DistanceSensor: Sensor {
    let recordingStart: Date
    var values: [DistanceValue]

    init(recordingStart: Date, values: [DistanceValue]) {
        self.recordingStart = recordingStart
        self.values = values
    }
}
