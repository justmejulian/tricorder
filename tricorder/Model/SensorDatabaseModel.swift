//
//  SensorDatabaseModel.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData

protocol SensorDatabaseModel: PersistentModel {
    associatedtype T: Value
    
    var sensorName: String { get }
    var recordingStart: Date { get }
    var data: T { get }
}
extension SensorDatabaseModel {
    // Used to pass around
    func toStruct<T>() throws -> SensorDatabaseModelStruct<T> {
        return try SensorDatabaseModelStruct<T>(sensor: self)
    }
}

@Model
class MotionSensorDatabaseModel: SensorDatabaseModel {
    var sensorName: String
    var recordingStart: Date
    var data: MotionValue

    init(sensorName: String, recordingStart: Date, data: MotionValue) {
        self.sensorName = sensorName
        self.recordingStart = recordingStart
        self.data = data
    }
    
    func toStruct() throws -> SensorDatabaseModelStruct<MotionValue> {
        return try toStruct<MotionValue>()
    }
}

@Model
class StatisticSensorDatabaseModel: SensorDatabaseModel {
    var sensorName: String
    var recordingStart: Date
    var data: StatisticValue

    init(sensorName: String, recordingStart: Date, data: StatisticValue) {
        self.sensorName = sensorName
        self.recordingStart = recordingStart
        self.data = data
    }
    
    func toStruct() throws -> SensorDatabaseModelStruct<StatisticValue> {
        return try toStruct<StatisticValue>()
    }
}

@Model
class DistanceSensorDatabaseModel: SensorDatabaseModel {
    var sensorName: String
    var recordingStart: Date
    var data: DistanceValue

    init(sensorName: String, recordingStart: Date, data: DistanceValue) {
        self.sensorName = sensorName
        self.recordingStart = recordingStart
        self.data = data
    }
    
    func toStruct() throws -> SensorDatabaseModelStruct<DistanceValue> {
        return try toStruct<DistanceValue>()
    }
}

struct SensorDatabaseModelStruct<T: Value> {
    let sensorName: String
    let recordingStart: Date
    let data: T

    init(sensor: any SensorDatabaseModel) throws {
        self.sensorName = sensor.sensorName
        self.recordingStart = sensor.recordingStart
        self.data = sensor.data as! T
    }
}

