//
//  MotionManager.swift
//  tricorder
//
//  Created by Julian Visser on 05.11.2024.
//

import Foundation
import OSLog

@MainActor
class MotionManager: ObservableObject {

    @Published
    var count = 0

    @Published
    var motionObservableValueManagers:
        [Sensor.MotionSensorName: ObservableValueManager<MotionValue>] = [:]
}

extension MotionManager {
    func reset() {
        count = 0
        motionObservableValueManagers = [:]
    }

    func update(sensorName: Sensor.MotionSensorName, newValues: [MotionValue]) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let observableValueManager = getOrCreateObservableValueManager(for: sensorName)

        count += newValues.count

        observableValueManager.update(newValues)
    }
}
extension MotionManager {
    private func getOrCreateObservableValueManager(for sensorName: Sensor.MotionSensorName)
        -> ObservableValueManager<MotionValue>
    {
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
