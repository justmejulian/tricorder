//
//  SettingDatabaseModel.swift
//
//  Created by Julian Visser on 08.12.2024.
//

import Foundation
import SwiftData

@Model
class SettingDatabaseModel {
    var useHighFrequencySensor: Bool = true

    var motionSensorRecodingRates: [Sensor.MotionSensorName: Int]

    init(
        useHighFrequencySensor: Bool,
        motionSensorRecodingRates: [Sensor.MotionSensorName: Int]
    ) {
        self.useHighFrequencySensor = useHighFrequencySensor
        self.motionSensorRecodingRates = motionSensorRecodingRates
    }

    init(settingDatabaseModelStruct: Settings) {
        self.useHighFrequencySensor = settingDatabaseModelStruct.useHighFrequencySensor
        self.motionSensorRecodingRates = settingDatabaseModelStruct.motionSensorRecodingRates
    }

    init() {
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
        self.useHighFrequencySensor = recording.useHighFrequencySensor
        self.motionSensorRecodingRates = recording.motionSensorRecodingRates
    }
}
