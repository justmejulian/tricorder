//
//  SettingDatabaseModel.swift
//
//  Created by Julian Visser on 08.12.2024.
//

import Foundation
import SwiftData

@Model
class SettingDatabaseModel {
    var failRate: Int

    var motionSensorRecodingRates: [Sensor.MotionSensorName: Int]

    init(failRate: Int, motionSensorRecodingRates: [Sensor.MotionSensorName: Int]) {
        self.failRate = failRate
        self.motionSensorRecodingRates = motionSensorRecodingRates
    }

    init(settingDatabaseModelStruct: SettingDatabaseModel.Struct) {
        self.failRate = settingDatabaseModelStruct.failRate
        self.motionSensorRecodingRates = settingDatabaseModelStruct.motionSensorRecodingRates
    }

    init() {
        self.failRate = 5

        let motionSensorRecodingRates = Sensor.MotionSensorName.allCases.reduce(
            into: [Sensor.MotionSensorName: Int]()
        ) { result, sensorName in
            result[sensorName] = getDefaultMotionsensorRecordingRate(sensorName: sensorName)
        }

        self.motionSensorRecodingRates = motionSensorRecodingRates
    }
}

extension SettingDatabaseModel {
    // Used to pass around
    struct Struct {
        let failRate: Int
        let motionSensorRecodingRates: [Sensor.MotionSensorName: Int]

        init(recording: SettingDatabaseModel) {
            self.failRate = recording.failRate
            self.motionSensorRecodingRates = recording.motionSensorRecodingRates
        }
    }

    func toStruct() -> Struct {
        return Struct(recording: self)
    }
}
