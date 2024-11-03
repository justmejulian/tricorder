//
//  StatisticsManager.swift
//  tricorder
//
//  Created by Julian Visser on 02.11.2024.
//

import Foundation
import HealthKit
import os

actor StatisticsManager: ObservableObject {
    var statistics: [HKStatistics] = []
    // todo store and stuff
}

extension StatisticsManager {
    func reset() {
        statistics = []
    }

    func updateForStatistics(_ statistics: HKStatistics) -> [StatisticsKey: Double] {
        Logger.shared.log("\(#function): \(statistics.debugDescription)")

        var mostRecentStatistic: [StatisticsKey: Double] = [:]

        switch statistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())

            mostRecentStatistic[.heartRate] =
                statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
                ?? 0

        default:
            Logger.shared.error("No case found for \(statistics.quantityType)")
        }

        return mostRecentStatistic
    }
}

enum StatisticsKey {
    case heartRate
}
