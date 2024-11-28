//
//  MotionSensorBackgroundDataHandler.swift
//
//  Created by Julian Visser on 26.11.2024.
//

import Foundation
import SwiftData
import os

actor MotionSensorBackgroundDataHandler {
    let backgroundDataHandler: BackgroundDataHandler
    let recordingBackgroundDataHandler: RecordingBackgroundDataHandler

    init(modelContainer: ModelContainer) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        self.backgroundDataHandler = BackgroundDataHandler(modelContainer: modelContainer)
        self.recordingBackgroundDataHandler = RecordingBackgroundDataHandler(
            modelContainer: modelContainer
        )
    }

    func add(motionSensor: MotionSensor) async throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        // get if recording exists

        let motionSensorBatchDatabaseModel = MotionSensorDatabaseModel(
            recordingStart: motionSensor.recordingStart,
            sensorName: motionSensor.sensorName,
            batch: motionSensor.batch
        )

        try await backgroundDataHandler.appendData(motionSensorBatchDatabaseModel)
    }

    func getMotionSensorPersistentIdentifiers(recordingStart: Date) async throws
        -> [PersistentIdentifier]
    {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let descriptor = FetchDescriptor<MotionSensorDatabaseModel>(
            predicate: #Predicate<MotionSensorDatabaseModel> {
                $0.recordingStart == recordingStart
            }
        )

        let persistentIdentifiers = try await backgroundDataHandler.fetchPersistentIdentifiers(
            descriptor: descriptor
        )

        return persistentIdentifiers
    }

}

enum MotionSensorBackgroundDataHandlerError: Error {
    case notFound
}
