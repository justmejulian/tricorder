//
//  RecordingBackgroundDataHandler.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData
import os

actor RecordingBackgroundDataHandler {
    let backgroundDataHandler: BackgroundDataHandler

    init(modelContainer: ModelContainer) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        self.backgroundDataHandler = BackgroundDataHandler(modelContainer: modelContainer)
    }

    func addNewRecording(name: String?, startTimestamp: Date = Date()) async throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let name = name ?? "Recording - \(startTimestamp.ISO8601Format())"

        let recording = RecordingDatabaseModel(name: name, startTimestamp: startTimestamp)
        try await backgroundDataHandler.appendData(recording)
    }

    func getRecordingPersistentIdentifierByStartTimestamp(startTimestamp: Date) async throws
        -> PersistentIdentifier
    {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let descriptor = FetchDescriptor<RecordingDatabaseModel>(
            predicate: #Predicate<RecordingDatabaseModel> {
                $0.startTimestamp == startTimestamp
            }
        )
        let persistentIdentifiers = try await backgroundDataHandler.fetchPersistentIdentifiers(
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
