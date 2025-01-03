//
//  SensorBackgroundDataHandler.swift
//
//  Created by Julian Visser on 26.11.2024.
//

import Foundation
import OSLog
import SwiftData

@ModelActor
actor SensorBackgroundDataHandler: BackgroundDataHandlerProtocol {
    func clear() throws {
        try deleteAllInstances(of: SensorDatabaseModel.self)
    }
}

extension SensorBackgroundDataHandler {
    func add(sensor: Sensor) async throws {

        // tood make sure recording exists

        let sensorDatabaseModel = try SensorDatabaseModel(
            recordingStart: sensor.recordingStartDate,
            sensor: sensor
        )

        try appendData(sensorDatabaseModel)
    }

    func getSensors(recordingStart: Date) throws
        -> [Sensor]
    {

        let descriptor = FetchDescriptor<SensorDatabaseModel>(
            predicate: #Predicate<SensorDatabaseModel> {
                $0.recordingStart == recordingStart
            }
        )

        let modelContext = createModelContext(
            modelContainer: modelContainer
        )

        let sensorPersistentModels = try modelContext.fetch(descriptor)

        let sensors = sensorPersistentModels.compactMap { $0.sensor }

        let countDiff = sensorPersistentModels.count - sensors.count

        if countDiff > 0 {
            Logger.shared.error("\(countDiff) sensor values were nil in sensorPersistentModels.")
        }

        let mergedSensors = try mergeSensors(
            sensors: sensors,
            recordingStart: recordingStart
        )

        return mergedSensors
    }

    func getSensorValueCounts(recordingStart: Date) throws
        -> [String: Int]
    {
        let sensors = try getSensors(recordingStart: recordingStart)
        return sensors.reduce(into: [:]) { result, sensor in
            result[sensor.name.rawValue] = sensor.valuesCount
        }
    }
}

extension SensorBackgroundDataHandler {

    private func mergeSensors(sensors: [Sensor], recordingStart: Date) throws
        -> [Sensor]
    {
        guard sensors.count > 0 else { return [] }

        let motionSensor = getEmpytSensorOfEach(recordingStart: recordingStart)

        let mergedSensorBatches = sensors.reduce(into: motionSensor) { result, sensor in
            guard let pastSensor = result[sensor.name.rawValue] else {
                Logger.shared.error(
                    "Could not find sensor name \(sensor.name.rawValue) in getEmpytSensorOfEach"
                )
                return
            }

            do {
                result[sensor.name.rawValue] = try mergeSensorValues(a: pastSensor, b: sensor)
            } catch {
                Logger.shared.error("Could not merge sensor values. \(error.localizedDescription)")
            }
        }

        return mergedSensorBatches.values.map { $0 }
    }

}

enum SensorBackgroundDataHandlerError: Error {
    case notFound
    case empty
}
