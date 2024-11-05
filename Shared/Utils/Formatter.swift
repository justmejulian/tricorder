//
//  Formatter.swift
//  tricorder
//
//  Created by Julian Visser on 05.11.2024.
//

import Foundation

func getLocalFormatter() -> MeasurementFormatter {

    let formatter = MeasurementFormatter()
    formatter.unitStyle = .medium
    formatter.unitOptions = .providedUnit
    formatter.numberFormatter.alwaysShowsDecimalSeparator = true
    formatter.numberFormatter.roundingMode = .ceiling
    formatter.numberFormatter.maximumFractionDigits = 1
    formatter.numberFormatter.minimumFractionDigits = 1
    return formatter
}
let localFormatter = getLocalFormatter()

func formatDistance(_ distance: Measurement<UnitLength>?) -> String {
    guard let distance else {
        return "-- m"
    }
    return localFormatter.string(from: distance)
}

func formatHeartRate(_ heartRate: Double?) -> String {
    guard let heartRate else {
        return "-- bpm"
    }
    return heartRate.formatted(
        .number.precision(.fractionLength(0))
    ) + " bpm"
}
