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

    func update(sensorName: String, newValues: [MotionValue]) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        let observableValueManager = getOrCreateObservableValueManager(for: sensorName)

        for newValue in newValues {
            count += 1
            observableValueManager.update(newValue)
        }
    }

    func update(motionSensor: MotionSensor) {
        update(sensorName: motionSensor.name, newValues: motionSensor.values)
    }
}
extension MotionManager {
    private func getOrCreateObservableValueManager(for sensorName: String)
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
