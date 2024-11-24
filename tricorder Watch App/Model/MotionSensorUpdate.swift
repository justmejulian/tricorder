//
//  MotionSensorUpdate.swift
//  tricorder
//
//  Created by Julian Visser on 23.11.2024.
//

import Foundation

struct MotionSensorUpdate: Sensor {
    let name: String
    let recordingStart: Date
    var values: [MotionValue]
}
