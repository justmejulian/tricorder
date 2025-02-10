//
//  FileCreator.swift
//
//  Created by Julian Visser on 01.12.2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileCreator {
    func generateJsonFile(fileName: String, data: Encodable) async throws -> File {
        let jsonData = try JSONEncoder().encode(data)
        return File(fileName: fileName, fileData: jsonData)
    }
}

struct File: FileDocument {
    static var readableContentTypes: [UTType] {
        [.json]
    }

    var fileData: Data
    var fileName: String

    init(fileName: String, fileData: Data) {
        self.fileData = fileData
        self.fileName = fileName
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw FileCreatorError.fileInitializationError
        }
        self.fileData = data
        self.fileName = "Untitled.json"
    }

    func fileWrapper(configuration: FileDocumentWriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: fileData)
    }
}

enum FileCreatorError: LocalizedError {
    case fileInitializationError

    var errorDescription: String? {
        switch self {
        case .fileInitializationError:
            return
                "Failed to initialize the file. Ensure the file path and permissions are correct."
        }
    }
}
