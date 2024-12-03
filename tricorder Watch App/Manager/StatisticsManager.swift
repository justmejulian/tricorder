//
//  StatisticsManager.swift
//  tricorder
//
//  Created by Julian Visser on 02.11.2024.
//

import Foundation
import HealthKit
import OSLog

actor StatisticsManager {
    var eventManager = EventManager.shared

    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())

    let recordingStartDate: Date

    init(recordingStartDate: Date) {
        self.recordingStartDate = recordingStartDate
    }
}

extension StatisticsManager {
    func handle(_ statistics: HKStatistics) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        switch statistics.quantityType {
        // Handle HeartRate
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
                        recordingStartDate: recordingStartDate,
                        batch: [
                            StatisticValue(
                                value: mostRecentHeartRate,
                                timestamp: Date()
                            )
                        ]
                    )
                ) as Void
            }

        //  timestamp: 2024-11-30 11:41:30 +0000))
        // 2024-11-30 11:41:44 +0000

        default:
            return
        }
    }
}
