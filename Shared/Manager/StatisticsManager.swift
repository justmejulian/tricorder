//
//  StatisticsManager.swift
//  tricorder
//
//  Created by Julian Visser on 02.11.2024.
//

import Foundation
import HealthKit
import os

@MainActor
class StatisticsManager: ObservableObject {
    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())

    @Published
    var statistics: [HKStatistics] = []
    @Published
    var mostRecentHeartRate: Double?
    @Published
    var avgHeartRate: Double?
}

extension StatisticsManager {
}

extension StatisticsManager {
    func reset() {
        statistics = []
    }

    func updateForStatistics(_ lastStatistics: HKStatistics) {
        Logger.shared.log("\(#function): \(lastStatistics)")

        statistics.append(lastStatistics)
        updateProperties(lastStatistics)
    }

    func updateProperties(_ lastStatistics: HKStatistics) {
        switch lastStatistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            mostRecentHeartRate = lastStatistics.mostRecentQuantity()?.doubleValue(
                for: heartRateUnit
            )
            avgHeartRate = lastStatistics.averageQuantity()?.doubleValue(for: heartRateUnit)

        default:
            return
        }
    }
}

enum StatisticsKey {
    case heartRate
}
