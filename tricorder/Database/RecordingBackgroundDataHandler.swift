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

    var cache: [Date: PersistentIdentifier] = [:]

    func clear() throws {
        try deleteAllInstances(of: RecordingDatabaseModel.self)
    }
}

extension RecordingBackgroundDataHandler {
    func addNewRecording(name: String?, startTimestamp: Date = Date()) throws {

        if (try getRecordingPersistentIdentifier(startTimestamp: startTimestamp)) != nil {
            Logger.shared.error("Recording already exists")
            return
        }

        let name = name ?? "Recording - \(startTimestamp.ISO8601Format())"

        let recording = RecordingDatabaseModel(name: name, startTimestamp: startTimestamp)
        try appendData(recording)
    }

    func fetchAllRecordingPersistentIdentifiers() async throws -> [PersistentIdentifier] {

        return try fetchPersistentIdentifiers(
            for: RecordingDatabaseModel.self
        )
    }

    func getRecordingPersistentIdentifier(startTimestamp: Date) throws
        -> PersistentIdentifier?
    {

        // Check cache
        if let persistentIdentifier = cache[startTimestamp] {
            return persistentIdentifier
        }

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

        cache[startTimestamp] = persistentIdentifier

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

enum RecordingBackgroundDataHandlerError: LocalizedError {
    case noRecordingFound

    var errorDescription: String? {
        switch self {
        case .noRecordingFound:
            return
                "No active recording was found. Ensure a recording session is started before accessing data."
        }
    }
}
