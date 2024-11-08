//
//  StatisticsManager.swift
//  tricorder
//
//  Created by Julian Visser on 02.11.2024.
//

import Foundation
import HealthKit
import os

// todo could this me just watch?
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
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        statistics = []
        mostRecentHeartRate = nil
        avgHeartRate = nil
    }

    func updateForStatistics(_ lastStatistics: HKStatistics) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        statistics.append(lastStatistics)
        updateProperties(lastStatistics)
    }

    func updateProperties(_ lastStatistics: HKStatistics) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

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
