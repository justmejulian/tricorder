//
//  Settings.swift
//
//  Created by Julian Visser on 10.12.2024.
//

struct Settings {
    let shouldFail: Bool
    let failRate: Int
    let motionSensorRecodingRates: [Sensor.MotionSensorName: Int]
}
