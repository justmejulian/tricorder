//
//  MotionObservableValueManager.swift
//  tricorder
//
//  Created by Julian Visser on 05.11.2024.
//

import Foundation
import OSLog

@MainActor
class MotionObservableValueManager: ObservableObject {

    @Published
    var count = 0

    @Published
    var motionObservableValueManagers:
        [Sensor.MotionSensorName: ObservableValueManager<MotionValue>] = [:]
}

extension MotionObservableValueManager {
    func reset() {
        count = 0
        motionObservableValueManagers = [:]
    }

    func update(sensorName: Sensor.MotionSensorName, newValues: [MotionValue]) {

        let observableValueManager = getOrCreateObservableValueManager(for: sensorName)

        count += newValues.count

        observableValueManager.update(newValues)
    }
}
extension MotionObservableValueManager {
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

enum MotionObservableValueManagerError: LocalizedError {
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "The motion data received is invalid or corrupted."
        }
    }
}
