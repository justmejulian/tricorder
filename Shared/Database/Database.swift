//
//  Database.swift
//
//  Created by Julian Visser on 24.11.2024.
//

// https://dev.to/jameson/swiftui-with-swiftdata-through-repository-36d1

import Foundation
import OSLog
import SwiftData

@MainActor
final class Database {
    private let modelContainer: ModelContainer

    // Main Model Context
    private let modelContext: ModelContext

    // todo take shema and use to handle errors
    init(modelContainer: ModelContainer) {
        Logger.shared.info("Creating Database")

        self.modelContainer = modelContainer
        self.modelContext = ModelContext(modelContainer)
        self.modelContext.autosaveEnabled = true
    }

    func getModelContainer() -> ModelContainer {
        return self.modelContainer
    }

    func clear() {
        Logger.shared.info("Deleting all Data from Database")
        self.modelContainer.deleteAllData()
    }
}
