//
//  Value.swift
//  tricorder
//
//  Created by Julian Visser on 05.11.2024.
//

// LogItem
// todo: CMAcceleration or CMRotationRate CMQuaternion
// LogItem with timestamp
struct Value: Codable {
    var x: Double
    var y: Double
    var z: Double
    var w: Double?

    var timestamp: Date

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
