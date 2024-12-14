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
    var motionSensors: [Sensor.MotionSensorName: Bool] = [:]
    var accelerometerRecordingRate: Int = 200
    var deviceMotionRecordingRate: Int = 200

    init() {
        let motionSensors = Sensor.MotionSensorName.allCases.reduce(
            into: [Sensor.MotionSensorName: Bool]()
        ) { result, sensorName in
            result[sensorName] = true
        }
        self.motionSensors = motionSensors
    }

    init(
        useHighFrequencySensor: Bool,
        motionSensors: [Sensor.MotionSensorName: Bool],
        accelerometerRecordingRate: Int,
        deviceMotionRecordingRate: Int
    ) {

        self.useHighFrequencySensor = useHighFrequencySensor
        self.accelerometerRecordingRate = accelerometerRecordingRate
        self.deviceMotionRecordingRate = deviceMotionRecordingRate
        self.motionSensors = motionSensors
    }

    init(settingDatabaseModelStruct: Settings) {
        self.useHighFrequencySensor = settingDatabaseModelStruct.useHighFrequencySensor
        self.motionSensors = settingDatabaseModelStruct.motionSensors
        self.accelerometerRecordingRate = settingDatabaseModelStruct.accelerometerRecordingRate
        self.deviceMotionRecordingRate = settingDatabaseModelStruct.deviceMotionRecordingRate
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
        self.motionSensors = recording.motionSensors
        self.accelerometerRecordingRate = recording.accelerometerRecordingRate
        self.deviceMotionRecordingRate = recording.deviceMotionRecordingRate
    }
}
