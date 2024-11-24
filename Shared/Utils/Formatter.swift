//
//  Formatter.swift
//  tricorder
//
//  Created by Julian Visser on 05.11.2024.
//

import Foundation

func formatDistance(_ distance: Double?) -> String {
    guard let distance else {
        return "-- m"
    }
    return "\(distance) m"
}

func formatHeartRate(_ heartRate: Double?) -> String {
    guard let heartRate else {
        return "-- bpm"
    }
    return heartRate.formatted(
        .number.precision(.fractionLength(0))
    ) + " bpm"
}
