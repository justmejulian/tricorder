//
//  MotionSensor.swift
//
//  Created by Julian Visser on 23.11.2024.
//

import Foundation

struct MotionSensor: Sensor {
    let name: String
    var values: [MotionValue]
}

extension MotionSensor {
    func chunked(into size: Int) throws -> [MotionSensor] {
        if values.count < size {
            return [self]
        }

        let chunks = values.chunked(into: size)

        return chunks.map {
            return MotionSensor(name: name, values: $0)
        }

    }
}
