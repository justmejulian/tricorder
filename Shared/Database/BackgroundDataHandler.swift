//
//  BackgroundDataHandler.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import OSLog
import SwiftData

@ModelActor
actor BackgroundDataHandler {
    var lastUpdate: Date? = nil
}

extension BackgroundDataHandler {
    private func createModelContext(modelContainer: ModelContainer) -> ModelContext {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let modelContext = ModelContext(modelContainer)
        modelContext.autosaveEnabled = false
        return modelContext
    }

    func save(modelContext: ModelContext) throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        lastUpdate = Date.now
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    func appendData<T>(_ data: T) where T: PersistentModel {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let modelContext = createModelContext(modelContainer: modelContainer)
        modelContext.insert(data)
        do {
            try save(modelContext: modelContext)
        } catch {
            Logger.shared.error("Failed to save from append \(error.localizedDescription)")
        }
    }

    func appendData<T>(_ dataArray: [T]) where T: PersistentModel {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let modelContext = createModelContext(modelContainer: modelContainer)
        for data in dataArray {
            modelContext.insert(data)
        }
        do {
            try save(modelContext: modelContext)
        } catch {
            Logger.shared.error("Failed to save from append \(error.localizedDescription)")
        }
    }

    func removeData(identifier: PersistentIdentifier) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let modelContext = createModelContext(modelContainer: modelContainer)
        let model = modelContext.model(for: identifier)
        modelContext.delete(model)
        do {
            try save(modelContext: modelContext)
        } catch {
            Logger.shared.error("Failed to save from append \(error.localizedDescription)")
        }
    }

    func fetchData<T>() -> [T] where T: PersistentModel {
        Logger.shared.debug("called on Thread \(Thread.current)")

        return fetchData(descriptor: FetchDescriptor<T>())
    }

    func fetchData<T>(descriptor: FetchDescriptor<T>) -> [T] where T: PersistentModel {
        Logger.shared.debug("called on Thread \(Thread.current)")

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Logger.shared.error("Failed to fetch \(T.self)")
            return []
        }
    }

    func fetchDataCount<T: PersistentModel>(for _: T.Type) -> Int {
        Logger.shared.debug("called on Thread \(Thread.current)")

        do {
            let descriptor = FetchDescriptor<T>()
            return try modelContext.fetchCount(descriptor)
        } catch {
            Logger.shared.error("Failed to fetch count \(T.self)")
            return 0
        }
    }

    func fetchPersistentIdentifiers<T>(for _: T.Type) -> [PersistentIdentifier]
    where T: PersistentModel {
        Logger.shared.debug("called on Thread \(Thread.current)")

        do {
            return try self.modelContext.fetchIdentifiers(FetchDescriptor<T>())
        } catch {
            Logger.shared.error("Failed to fetch Identifiers for \(T.self)")
            return []
        }
    }

}
