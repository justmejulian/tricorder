//
//  PersistedDataHandler.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import OSLog
import SwiftData

@ModelActor
actor PersistedDataHandler: BackgroundDataHandlerProtocol {
    func clear() throws {
        try deleteAllInstances(of: PersistedDatabaseModel.self)
    }
}

extension PersistedDataHandler {
    func add(data: Data) throws {

        let persistedData = PersistedDatabaseModel(data: data)

        try appendData(persistedData)
    }

    func add(dataArray: [Data]) throws {

        for data in dataArray {
            try add(data: data)
        }
    }

    func fetchAllPersistentIdentifiers() async throws -> [PersistentIdentifier] {

        return try fetchPersistentIdentifiers(
            for: PersistedDatabaseModel.self
        )
    }

    func getData(for identifier: PersistentIdentifier) async throws -> Data {
        let modelContext = createModelContext(
            modelContainer: modelContainer
        )

        guard let model = modelContext.model(for: identifier) as? PersistedDatabaseModel else {
            throw PersistedDataHandlerError.notFound
        }

        return model.data
    }

    func getData(for identifiers: [PersistentIdentifier]) async throws -> [Data] {
        let modelContext = createModelContext(
            modelContainer: modelContainer
        )

        let data = try identifiers.map { identifier in
            guard let model = modelContext.model(for: identifier) as? PersistedDatabaseModel else {
                throw PersistedDataHandlerError.notFound
            }

            return model.data
        }

        return data
    }

    func getData() async throws -> [Data] {
        let descriptor = FetchDescriptor<PersistedDatabaseModel>()
        let modelContext = createModelContext(
            modelContainer: modelContainer
        )

        let persistedDatabaseModel = try modelContext.fetch(descriptor)

        let data = persistedDatabaseModel.map { $0.data }

        return data
    }

    func removeData(identifiers: [PersistentIdentifier]) throws {

        let modelContext = createModelContext(modelContainer: modelContainer)
        for identifier in identifiers {
            let model = modelContext.model(for: identifier)
            modelContext.delete(model)
        }
        try save(modelContext: modelContext)
    }
}

enum PersistedDataHandlerError: LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "The requested persisted data was not found."
        }
    }
}
