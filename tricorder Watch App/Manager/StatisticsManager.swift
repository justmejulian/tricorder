//
//  StatisticsManager.swift
//  tricorder
//
//  Created by Julian Visser on 02.11.2024.
//

import Foundation
import HealthKit
import os

actor StatisticsManager {
    var eventManager = EventManager.shared

    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
}

extension StatisticsManager {
    func handle(_ statistics: HKStatistics) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        switch statistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            guard
                let mostRecentHeartRate = statistics.mostRecentQuantity()?.doubleValue(
                    for: heartRateUnit
                )
            else {
                Logger.shared.error("\(#function) failed to extract heart rate value")
                return
            }

            Logger.shared.debug("\(statistics.startDate)")

            Task {
                await eventManager.trigger(
                    key: .collectedSensorValues,
                    data: Sensor.statistic(
                        .heartRate,
                        recordingStartDate: statistics.startDate,
                        batch: StatisticValue(
                            value: mostRecentHeartRate,
                            timestamp: Date()
                        )
                    )
                ) as Void
            }

        default:
            return
        }
    }
}
