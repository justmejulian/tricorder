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

        let recordingId = try await recordingBackgroundDataHandler.getRecordingPersistentIdentifier(
            startTimestamp: motionSensor.recordingStart
        )

        let motionSensorBatchDatabaseModel = MotionSensorDatabaseModel(
            recordingId: recordingId,
            sensorName: motionSensor.sensorName,
            batch: motionSensor.batch
        )

        try await backgroundDataHandler.appendData(motionSensorBatchDatabaseModel)
    }

    func getMotionSensorPersistentIdentifiers(recordingId: PersistentIdentifier) async throws
        -> [PersistentIdentifier]
    {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let descriptor = FetchDescriptor<MotionSensorDatabaseModel>(
            predicate: #Predicate<MotionSensorDatabaseModel> {
                $0.recordingId == recordingId
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
