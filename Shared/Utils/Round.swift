//
//  Round.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation

// Round to the specific decimal place
func roundToDecimal(_ value: Double, decimals: Int) -> Double {
    let precision = pow(10.0, Double(decimals))
    return round(value * precision) / precision
}
