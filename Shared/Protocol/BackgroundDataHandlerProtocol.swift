//
//  BackgroundDataHandler.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import OSLog
import SwiftData

protocol BackgroundDataHandlerProtocol: Actor {
    nonisolated var modelExecutor: any SwiftData.ModelExecutor { get }
    nonisolated var modelContainer: SwiftData.ModelContainer { get }

    func clear() throws
}
extension BackgroundDataHandlerProtocol {
    func createModelContext(modelContainer: ModelContainer) -> ModelContext {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let modelContext = ModelContext(modelContainer)
        modelContext.autosaveEnabled = false
        return modelContext
    }

    func save(modelContext: ModelContext) throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    func appendData<T>(_ dataArray: [T]) throws where T: PersistentModel {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let modelContext = createModelContext(modelContainer: modelContainer)
        for data in dataArray {
            modelContext.insert(data)
        }
        try save(modelContext: modelContext)
    }

    func appendData<T>(_ data: T) throws where T: PersistentModel {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let modelContext = createModelContext(modelContainer: modelContainer)
        modelContext.insert(data)
        try save(modelContext: modelContext)
    }

    func removeData(identifier: PersistentIdentifier) throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let modelContext = createModelContext(modelContainer: modelContainer)
        let model = modelContext.model(for: identifier)
        modelContext.delete(model)
        try save(modelContext: modelContext)
    }

    func fetchDataCount<T: PersistentModel>(for _: T.Type) throws -> Int {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let descriptor = FetchDescriptor<T>()

        let modelContext = createModelContext(modelContainer: modelContainer)
        return try modelContext.fetchCount(descriptor)
    }

    func fetchPersistentIdentifiers<T>(for _: T.Type) throws -> [PersistentIdentifier]
    where T: PersistentModel {
        Logger.shared.debug("called on Thread \(Thread.current)")

        return try fetchPersistentIdentifiers(descriptor: FetchDescriptor<T>())
    }

    func fetchPersistentIdentifiers<T>(descriptor: FetchDescriptor<T>) throws
        -> [PersistentIdentifier] where T: PersistentModel
    {
        Logger.shared.debug("called on Thread \(Thread.current)")
        let modelContext = createModelContext(modelContainer: modelContainer)
        return try modelContext.fetchIdentifiers(descriptor)
    }

    func deleteAllInstances<T: PersistentModel>(of modelType: T.Type) throws {
        let modelContext = createModelContext(modelContainer: modelContainer)

        let fetchDescriptor = FetchDescriptor<T>()
        let results = try modelContext.fetch(fetchDescriptor)

        // Delete each instance
        for object in results {
            modelContext.delete(object)
        }

        // Save the changes to persist the deletions
        try modelContext.save()
    }
}
