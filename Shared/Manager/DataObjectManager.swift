//
//  DataObject.swift
//  tricorder
//
//  Created by Julian Visser on 31.10.2024.
//

import Foundation

struct DataObjectManager {

    // Unified DataObject used to send and recieve
    struct DataObject: Codable {
        var key: String
        var data: Data
    }

    func encode(key: String, data: Data) throws -> Data {
        let dataObject = DataObject(key: key, data: data)
        guard let encodedData = try? JSONEncoder().encode(dataObject) else {
            throw DataObjectManagerError.couldNotEncodeData
        }
        return encodedData
    }

    func decode(_ data: Data) throws -> DataObject {
        guard
            let dataObject = try? JSONDecoder().decode(
                DataObject.self, from: data)
        else {
            throw DataObjectManagerError.couldNotDecodeData
        }

        return dataObject
    }
}

// MARK: - DataObjectManagerError
//
enum DataObjectManagerError: Error {
    case couldNotEncodeData
    case couldNotDecodeData
}
