//
//  DistanceValue.swift
//
//  Created by Julian Visser on 23.11.2024.
//

import Foundation

struct DistanceValue: Value {
    let value: Double

    var timestamp: Date

    init(value: Double, timestamp: Date) {
        self.value = value
        self.timestamp = timestamp
    }
}
