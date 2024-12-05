//
//  ClassifierManager.swift
//
//  Created by Julian Visser on 05.12.2024.
//

import Foundation
import OSLog

@MainActor
class ClassifierManager: BaseClassifierManager {
    var motionManager = MotionManager()
    var distanceManager = ObservableValueManager<DistanceValue>()
    var heartRateManager = ObservableValueManager<StatisticValue>()

    @Published
    var distanceChartValues: [LineChart.DataPoint] = []

    @Published
    var topSpeed: Double = 0

    func reset() {
        Logger.shared.debug("called on Thread \(Thread.current)")

        distanceManager.reset()
        heartRateManager.reset()
        motionManager.reset()

        distanceChartValues = []
        topSpeed = 0
    }

    func update(_ sensor: Sensor) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        switch sensor {
        case .motion(let name, let recordingStart, let values):
            motionManager.update(
                sensorName: name,
                newValues: values
            )
        case .statistic(let name, let recordingStart, let values):
            heartRateManager.update(values)
        case .distance(let name, let recordingStart, let values):
            distanceManager.update(values)
        }
    }
}