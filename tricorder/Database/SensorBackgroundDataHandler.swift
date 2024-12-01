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
        try deleteAllInstances(of: RecordingDatabaseModel.self)
    }
}

extension SensorBackgroundDataHandler {
    func add(sensor: Sensor) async throws {
        Logger.shared.debug("called on Thread \(Thread.current)")
        Logger.shared.debug("\(String.init(describing: sensor))")

        // tood make sure recording exists

        let sensorData = try getSensorData(sensor: sensor)

        let motionSensorBatchDatabaseModel = SensorDatabaseModel(
            sensorName: sensorData.name,
            recordingStart: sensorData.recordingStartDate,
            data: sensorData.data
        )

        try self.appendData(motionSensorBatchDatabaseModel)
    }

    private func getSensorData(sensor: Sensor) throws -> (
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

    func getSensorData(recordingStart: Date) async throws -> [SensorDatabaseModel.Struct] {
        let descriptor = FetchDescriptor<SensorDatabaseModel>(
            predicate: #Predicate<SensorDatabaseModel> {
                $0.recordingStart == recordingStart
            }
        )
        let modelContext = createModelContext(
            modelContainer: modelContainer
        )
        let sensorData = try modelContext.fetch(descriptor)

        let sensorValues: [SensorDatabaseModel.Struct] = sensorData.map { $0.toStruct() }

        return sensorValues
    }

    func getMergedSensorData(recordingStart: Date) async throws -> [String: [Data]] {
        let sensorValues = try await getSensorData(recordingStart: recordingStart)
        let mergedSensorValues = sensorValues.reduce(into: [:]) { result, sensorValue in
            result[sensorValue.sensorName, default: []].append(sensorValue.data)
        }

        return mergedSensorValues
    }

    func getSensorValueBytes(recordingStart: Date) async throws -> [String: Int] {
        let sensorValues = try await getSensorData(recordingStart: recordingStart)
        return sensorValues.reduce(into: [:]) { result, sensorValue in
            let bytes = sensorValue.data.count
            result[sensorValue.sensorName, default: 0] += bytes
        }
    }
}

extension SensorBackgroundDataHandler {
}

enum SensorBackgroundDataHandlerError: Error {
    case notFound
}
