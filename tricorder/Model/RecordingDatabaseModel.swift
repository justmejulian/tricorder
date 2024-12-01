//
//  RecordingDatabaseModel.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData

@Model
class RecordingDatabaseModel {

    var name: String
    var startTimestamp: Date

    init(startTimestamp: Date) {
        self.name = "Recording - \(startTimestamp.ISO8601Format())"
        self.startTimestamp = startTimestamp
    }

    init(name: String, startTimestamp: Date) {
        self.name = name
        self.startTimestamp = startTimestamp
    }
}

extension RecordingDatabaseModel {
    // Used to pass around
    struct Struct {
        let name: String
        let startTimestamp: Date

        init(recording: RecordingDatabaseModel) {
            self.name = recording.name
            self.startTimestamp = recording.startTimestamp
        }
    }
    
    func toStruct() -> Struct {
        return Struct(recording: self)
    }
}
