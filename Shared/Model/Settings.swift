//
//  Settings.swift
//
//  Created by Julian Visser on 10.12.2024.
//

struct Settings: Codable {
    let useHighFrequencySensor: Bool
    let motionSensorRecodingRates: [Sensor.MotionSensorName: Int]
}
