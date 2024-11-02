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
    @Published var heartRate: Double = 0
}

extension StatisticsManager {
    func reset() {
        heartRate = 0
        statistics = []
    }
    
    func updateForStatistics(_ statistics: HKStatistics) {
        Logger.shared.log("\(#function): \(statistics.debugDescription)")

        switch statistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            heartRate =
                statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
                ?? 0

        default:
            return
        }
    }
}
