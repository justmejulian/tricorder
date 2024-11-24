//
//  Value.swift
//  tricorder
//
//  Created by Julian Visser on 05.11.2024.
//

import Foundation

// todo can I do some type magic?
struct MotionValue: Value {
    let x: Double
    let y: Double
    let z: Double
    let w: Double?

    let timestamp: Date

    // Values may have 3 or 4 Datapoints
    init(x: Double, y: Double, z: Double, timestamp: Date) {
        self.x = x
        self.y = y
        self.z = z
        self.w = nil
        self.timestamp = timestamp
    }

    init(x: Double, y: Double, z: Double, w: Double, timestamp: Date) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
        self.timestamp = timestamp
    }
}
