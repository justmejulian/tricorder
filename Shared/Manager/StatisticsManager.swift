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
    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())

    @Published
    var statistics: [HKStatistics] = []
    // todo store and stuff

    var mostRecentHeartRate: Double? {
        guard let lastStatistics = statistics.last else {
            return nil
        }

        if let mostRecentHeartRate = lastStatistics.mostRecentQuantity()?.doubleValue(
            for: heartRateUnit
        ) {
            return mostRecentHeartRate
        }

        return nil
    }
}

extension StatisticsManager {
    func reset() {
        statistics = []
    }

    func updateForStatistics(_ lastStatistics: HKStatistics) {
        Logger.shared.log("\(#function): \(lastStatistics.debugDescription)")

        statistics.append(lastStatistics)
    }

    func getMostReacentValue(for hkUnit: HKUnit) -> Double? {
        guard let lastStatistics = statistics.last else {
            return nil
        }

        return lastStatistics.mostRecentQuantity()?.doubleValue(for: hkUnit)
    }

    func getDoubleValue(hkQuantity: HKQuantity?, hkUnit: HKUnit) -> Double? {
        guard let hkQuantity else {
            return 0
        }

        return hkQuantity.doubleValue(for: hkUnit)
    }
}

enum StatisticsKey {
    case heartRate
}
