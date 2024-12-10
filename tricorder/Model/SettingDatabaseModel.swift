//
//  SettingDatabaseModel.swift
//
//  Created by Julian Visser on 08.12.2024.
//

import Foundation
import SwiftData

@Model
class SettingDatabaseModel {
    var shouldFail: Bool
    var failRate: Int

    var motionSensorRecodingRates: [Sensor.MotionSensorName: Int]

    init(shouldFail: Bool, failRate: Int, motionSensorRecodingRates: [Sensor.MotionSensorName: Int])
    {
        self.shouldFail = shouldFail
        self.failRate = failRate
        self.motionSensorRecodingRates = motionSensorRecodingRates
    }

    init(settingDatabaseModelStruct: Settings) {
        self.shouldFail = settingDatabaseModelStruct.shouldFail
        self.failRate = settingDatabaseModelStruct.failRate
        self.motionSensorRecodingRates = settingDatabaseModelStruct.motionSensorRecodingRates
    }

    init() {
        self.shouldFail = false
        self.failRate = 100

        let motionSensorRecodingRates = Sensor.MotionSensorName.allCases.reduce(
            into: [Sensor.MotionSensorName: Int]()
        ) { result, sensorName in
            result[sensorName] = getDefaultMotionsensorRecordingRate(sensorName: sensorName)
        }

        self.motionSensorRecodingRates = motionSensorRecodingRates
    }
}

extension SettingDatabaseModel {
    func toStruct() -> Settings {
        return Settings(recording: self)
    }
}

extension Settings {
    init(recording: SettingDatabaseModel) {
        self.shouldFail = recording.shouldFail
        self.failRate = recording.failRate
        self.motionSensorRecodingRates = recording.motionSensorRecodingRates
    }
}
