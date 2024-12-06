//
//  RecordingBackgroundDataHandler.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import OSLog
import SwiftData

@ModelActor
actor RecordingBackgroundDataHandler: BackgroundDataHandlerProtocol {
    func clear() throws {
        try deleteAllInstances(of: RecordingDatabaseModel.self)
    }
}

extension RecordingBackgroundDataHandler {
    func addNewRecording(name: String?, startTimestamp: Date = Date()) throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let name = name ?? "Recording - \(startTimestamp.ISO8601Format())"

        let recording = RecordingDatabaseModel(name: name, startTimestamp: startTimestamp)
        try appendData(recording)
    }

    func fetchAllRecordingPersistentIdentifiers() async throws -> [PersistentIdentifier] {
        Logger.shared.debug("called on Thread \(Thread.current)")

        return try fetchPersistentIdentifiers(
            for: RecordingDatabaseModel.self
        )
    }

    func conditionallyAddRecording(startTimestamp: Date) throws {
        if (try getRecordingPersistentIdentifier(startTimestamp: startTimestamp)) != nil {
            return
        }

        try addNewRecording(name: nil, startTimestamp: startTimestamp)
    }

    func getRecordingPersistentIdentifier(startTimestamp: Date) throws
        -> PersistentIdentifier?
    {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let descriptor = FetchDescriptor<RecordingDatabaseModel>(
            predicate: #Predicate<RecordingDatabaseModel> {
                $0.startTimestamp == startTimestamp
            }
        )
        let persistentIdentifiers = try fetchPersistentIdentifiers(
            descriptor: descriptor
        )

        if persistentIdentifiers.count > 1 {
            fatalError("Found multiple recordings for \(startTimestamp)")
        }

        guard let persistentIdentifier = persistentIdentifiers.first else {
            return nil
        }

        return persistentIdentifier
    }

    func getRecording(recordingStart: Date) async throws -> RecordingDatabaseModel.Struct {
        let descriptor = FetchDescriptor<RecordingDatabaseModel>(
            predicate: #Predicate<RecordingDatabaseModel> {
                $0.startTimestamp == recordingStart
            }
        )

        let modelContext = createModelContext(
            modelContainer: modelContainer
        )

        let recordings = try modelContext.fetch(descriptor)

        if recordings.count > 1 {
            Logger.shared.error("Multiple recordings found for \(recordingStart).")
        }

        guard let recording = recordings.first else {
            throw RecordingBackgroundDataHandlerError.noRecordingFound
        }

        return recording.toStruct()
    }

    func getRecordings() async throws -> [RecordingDatabaseModel.Struct] {
        let descriptor = FetchDescriptor<RecordingDatabaseModel>()
        let modelContext = createModelContext(
            modelContainer: modelContainer
        )

        let recordingPersistentModels = try modelContext.fetch(descriptor)

        let recordings = recordingPersistentModels.map { $0.toStruct() }

        return recordings
    }
}

enum RecordingBackgroundDataHandlerError: Error {
    case noRecordingFound
}
