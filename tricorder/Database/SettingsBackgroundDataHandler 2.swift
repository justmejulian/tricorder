//
//  SettingsBackgroundDataHandler.swift
//
//  Created by Julian Visser on 08.12.2024.
//

import Foundation
import OSLog
import SwiftData

@ModelActor
actor SettingsBackgroundDataHandler: BackgroundDataHandlerProtocol {
    func clear() throws {
        try deleteAllInstances(of: SettingDatabaseModel.self)
    }
}

extension SettingsBackgroundDataHandler {
    func add(_ settings: SettingDatabaseModel.Struct) throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        if (try getSettingsPersistentIdentifier()) != nil {
            throw SettingsBackgroundDataHandlerError.alreadyCreated
        }

        let settingsModel = SettingDatabaseModel(settingDatabaseModelStruct: settings)
        try appendData(settingsModel)
    }

    func getSettingsPersistentIdentifier() throws
        -> PersistentIdentifier?
    {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let descriptor = FetchDescriptor<SettingDatabaseModel>()
        let persistentIdentifiers = try fetchPersistentIdentifiers(
            descriptor: descriptor
        )

        if persistentIdentifiers.count > 1 {
            fatalError("Found multiple settings")
        }

        guard let persistentIdentifier = persistentIdentifiers.first else {
            return nil
        }

        return persistentIdentifier
    }

    func getSettings() async throws -> SettingDatabaseModel.Struct {
        let descriptor = FetchDescriptor<SettingDatabaseModel>()

        let modelContext = createModelContext(
            modelContainer: modelContainer
        )

        let settingsArray = try modelContext.fetch(descriptor)

        if settingsArray.count > 1 {
            fatalError("Found multiple settings")
        }

        guard let settings = settingsArray.first else {
            throw RecordingBackgroundDataHandlerError.noRecordingFound
        }

        return settings.toStruct()
    }

}

enum SettingsBackgroundDataHandlerError: Error {
    case alreadyCreated
}
