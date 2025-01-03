//
//  ClassifierManager.swift
//
//  Created by Julian Visser on 05.12.2024.
//

import Foundation
import OSLog

@MainActor
class ClassifierManager: BaseClassifierManager {
    var motionManager = MotionObservableValueManager()
    var distanceManager = ObservableValueManager<DistanceValue>()
    var heartRateManager = ObservableValueManager<StatisticValue>()

    var topAccelerationClassifier = TopAccelerationClassifier()

    @Published
    var distanceChartValues: [LineChart.DataPoint] = []

    @Published
    var topAcceleration: Double = 0

    func reset() async {

        distanceManager.reset()
        heartRateManager.reset()
        motionManager.reset()

        await topAccelerationClassifier.reset()

        distanceChartValues = []
        topAcceleration = 0
    }

    func update(_ sensor: Sensor) async {

        switch sensor {
        case .motion(let name, _, let values):
            motionManager.update(
                sensorName: name,
                newValues: values
            )

            if name == .userAcceleration {
                topAcceleration = await topAccelerationClassifier.handleAccelerationUpdate(values)
            }

        case .statistic(_, _, let values):
            heartRateManager.update(values)

        case .distance(_, _, let values):
            distanceManager.update(values)
            updateDistaceChartValues(values)
        }
    }
}

extension ClassifierManager {
    func updateDistaceChartValues(_ values: [DistanceValue]) {
        for value in values {
            let point = LineChart.DataPoint(timestamp: value.timestamp, value: value.value)
            distanceChartValues.append(point)
        }
    }
}
