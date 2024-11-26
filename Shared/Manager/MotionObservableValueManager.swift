//
//  MotionManager.swift
//  tricorder
//
//  Created by Julian Visser on 05.11.2024.
//

import Foundation
import os

@MainActor
class MotionManager: ObservableObject {

    @Published
    var count = 0

    @Published
    var motionObservableValueManagers: [String: ObservableValueManager<MotionValue>] = [:]
}

extension MotionManager {
    func reset() {
        count = 0
        motionObservableValueManagers = [:]
    }

    func update(sensorName: MotionSensor.SensorName, newValues: [MotionValue]) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let observableValueManager = getOrCreateObservableValueManager(for: sensorName)

        for newValue in newValues {
            count += 1
            observableValueManager.update(newValue)
        }
    }
}
extension MotionManager {
    private func getOrCreateObservableValueManager(for sensorName: MotionSensor.SensorName)
        -> ObservableValueManager<MotionValue>
    {
        let sensorName = sensorName.rawValue
        guard let observableValueManager = motionObservableValueManagers[sensorName] else {
            let observableValueManager = ObservableValueManager<MotionValue>()
            motionObservableValueManagers[sensorName] = observableValueManager
            return observableValueManager
        }

        return observableValueManager
    }
}

enum MotionManagerError: Error {
    case invalidData
}
