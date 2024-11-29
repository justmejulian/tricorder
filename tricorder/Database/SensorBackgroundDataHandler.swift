//
//  SensorBackgroundDataHandler.swift
//
//  Created by Julian Visser on 26.11.2024.
//

import Foundation
import SwiftData
import os

actor SensorBackgroundDataHandler {
    let backgroundDataHandler: BackgroundDataHandler
    let recordingBackgroundDataHandler: RecordingBackgroundDataHandler

    init(modelContainer: ModelContainer) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        self.backgroundDataHandler = BackgroundDataHandler(modelContainer: modelContainer)
        self.recordingBackgroundDataHandler = RecordingBackgroundDataHandler(
            modelContainer: modelContainer
        )
    }

    func add(sensor: Sensor) async throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        // tood make sure recording exists

        let sensorData = try getSensoData(sensor: sensor)

        let motionSensorBatchDatabaseModel = SensorDatabaseModel(
            sensorName: sensorData.name,
            recordingStart: sensorData.recordingStartDate,
            data: sensorData.data
        )

        try await backgroundDataHandler.appendData(motionSensorBatchDatabaseModel)
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

    func getMotionSensorPersistentIdentifiers(recordingStart: Date) async throws
        -> [PersistentIdentifier]
    {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let descriptor = FetchDescriptor<SensorDatabaseModel>(
            predicate: #Predicate<SensorDatabaseModel> {
                $0.recordingStart == recordingStart
            }
        )

        let persistentIdentifiers = try await backgroundDataHandler.fetchPersistentIdentifiers(
            descriptor: descriptor
        )

        return persistentIdentifiers
    }

}

enum SensorBackgroundDataHandlerError: Error {
    case notFound
}
