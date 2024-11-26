//
//  Sensor.swift
//
//  Created by Julian Visser on 05.11.2024.
//

import Foundation

protocol Sensor: Codable {
    associatedtype T: Value

    var recordingStart: Date { get }
    var values: [T] { get set }
}

// todo add enum with names
