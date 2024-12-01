//
//  RecordingBackgroundDataHandler.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData
import OSLog

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

    func getRecordingPersistentIdentifier(startTimestamp: Date) throws
        -> PersistentIdentifier
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
            throw RecordingBackgroundDataHandlerError.noRecordingFound
        }

        return persistentIdentifier
    }
}

enum RecordingBackgroundDataHandlerError: Error {
    case noRecordingFound
}
