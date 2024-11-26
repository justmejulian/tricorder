//
//  Value.swift
//
//  Created by Julian Visser on 05.11.2024.
//

import Foundation
import SwiftData

protocol Value: Codable {
    var timestamp: Date { get }
}
