//
//  PersistedDatabaseModel.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData

@Model
class PersistedDatabaseModel {
    var data: Data

    init(data: Data) {
        self.data = data
    }
}
