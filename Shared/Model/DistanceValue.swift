//
//  DistanceValue.swift
//
//  Created by Julian Visser on 23.11.2024.
//

import Foundation

struct DistanceValue: Value {
    let values: [Double]

    var avg: Double {
        let sum = values.reduce(0, +)
        let avg = sum / Double(values.count)
        return roundToDecimal(avg, decimals: 1)
    }

    var timestamp: Date

    init(values: [Double], timestamp: Date) {
        self.values = values.map { roundToDecimal($0, decimals: 1) }
        self.timestamp = timestamp
    }
}
