//
//  DataObject.swift
//  tricorder
//
//  Created by Julian Visser on 31.10.2024.
//

import Foundation
import OSLog

struct SendDataObjectManager {

    // Unified DataObject used to send and recieve
    struct DataObject: Codable {
        var key: String
        var data: Data
    }

    func encode(key: String, data: Data) throws -> Data {

        let dataObject = DataObject(key: key, data: data)
        guard let encodedData = try? JSONEncoder().encode(dataObject) else {
            throw SendDataObjectManagerError.couldNotEncodeData
        }
        return encodedData
    }

    func decode(_ data: Data) throws -> DataObject {

        guard
            let dataObject = try? JSONDecoder().decode(
                DataObject.self,
                from: data
            )
        else {
            throw SendDataObjectManagerError.couldNotDecodeData
        }

        return dataObject
    }

    func decode(_ data: Sendable) throws -> DataObject {
        guard let data = data as? Data else {
            throw SendDataObjectManagerError.couldNotDecodeData
        }

        return try decode(data)
    }
}

// MARK: - SendDataObjectManagerError
//
enum SendDataObjectManagerError: LocalizedError {
    case couldNotEncodeData
    case couldNotDecodeData

    var errorDescription: String? {
        switch self {
        case .couldNotEncodeData:
            return "Failed to encode the data before sending."
        case .couldNotDecodeData:
            return "Failed to decode the received data."
        }
    }
}
