//
//  SensorBackgroundDataHandler.swift
//
//  Created by Julian Visser on 26.11.2024.
//

import Foundation
import SwiftData
import os

@ModelActor
actor SensorBackgroundDataHandler: BackgroundDataHandlerProtocol {
    func clear() throws {
        try deleteAllInstances(of: RecordingDatabaseModel.self)
    }
}

extension SensorBackgroundDataHandler {
    func add(sensor: Sensor) async throws {
        Logger.shared.debug("called on Thread \(Thread.current)")
        Logger.shared.debug("\(String.init(describing: sensor))")

        // tood make sure recording exists

        let sensorData = try getSensoData(sensor: sensor)

        let motionSensorBatchDatabaseModel = SensorDatabaseModel(
            sensorName: sensorData.name,
            recordingStart: sensorData.recordingStartDate,
            data: sensorData.data
        )

        try self.appendData(motionSensorBatchDatabaseModel)
    }

    private func getSensoData(sensor: Sensor) throws -> (
        name: String, recordingStartDate: Date, data: Data
    ) {
        switch sensor {
        case .motion(let name, let recordingStartDate, let batch):
            return (
                name: name.rawValue, recordingStartDate: recordingStartDate,
                data: try JSONEncoder().encode(batch)
            )

        case .statistic(let name, let recordingStartDate, let batch):
            return (
                name: name.rawValue, recordingStartDate: recordingStartDate,
                data: try JSONEncoder().encode(batch)
            )
        case .distance(let name, let recordingStartDate, let batch):
            return (
                name: name.rawValue, recordingStartDate: recordingStartDate,
                data: try JSONEncoder().encode(batch)
            )
        }
    }

    func getSensorPersistentIdentifiers(recordingStart: Date) throws
        -> [PersistentIdentifier]
    {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let descriptor = FetchDescriptor<SensorDatabaseModel>(
            predicate: #Predicate<SensorDatabaseModel> {
                $0.recordingStart == recordingStart
            }
        )

        let persistentIdentifiers = try fetchPersistentIdentifiers(
            descriptor: descriptor
        )

        return persistentIdentifiers
    }

    func getSensorsData(recordingStart: Date) async throws -> [String: [Data]] {
        let descriptor = FetchDescriptor<SensorDatabaseModel>(
            predicate: #Predicate<SensorDatabaseModel> {
                $0.recordingStart == recordingStart
            }
        )
        let modelContext = createModelContext(
            modelContainer: modelContainer
        )
        let sensorData = try modelContext.fetch(descriptor)

        let sensorValues: [String: [Data]] = sensorData.reduce(into: [:]) { result, sensor in
            result[sensor.sensorName, default: []].append(sensor.data)
        }

        return sensorValues
    }

    func getSensorValueBytes(recordingStart: Date) async throws -> [String: Int] {
        let sensorValues = try await getSensorsData(recordingStart: recordingStart)
        return sensorValues.reduce(into: [:]) { result, sensorValue in
            let bytes = sensorValue.value.reduce(0) { result, value in
                result + value.count
            }

            result[sensorValue.key, default: 0] += bytes
        }
    }
}

extension SensorBackgroundDataHandler {
}

enum SensorBackgroundDataHandlerError: Error {
    case notFound
}
