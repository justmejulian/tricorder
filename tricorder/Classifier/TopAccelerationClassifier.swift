//
//  TopAccelerationClassifier.swift
//
//  Created by Julian Visser on 05.12.2024.
//

import Foundation

actor TopAccelerationClassifier {
    private var topAcceleration: Double = 0

    func reset() {
        topAcceleration = 0
    }

    func handleAccelerationUpdate(_ accelerationValues: [MotionValue]) -> Double {
        let accelerationValues = splitValuesIntoTimeChunks(accelerationValues)
        let averageResultantAcceleration = accelerationValues.values.map { values in
            return self.averageResultantAcceleration(values)
        }

        let newTopAcceleration = getNewTopAcceleration(averageResultantAcceleration)

        topAcceleration = newTopAcceleration

        return topAcceleration
    }

    private func getNewTopAcceleration(_ accelerationValues: [Double]) -> Double {
        let sortedAverageResultantAcceleration = accelerationValues.sorted()

        guard let updateTopAcceleration = sortedAverageResultantAcceleration.last else {
            return topAcceleration
        }

        let roundedUpdateTopAcceleration = roundToDecimal(updateTopAcceleration, decimals: 2)

        return max(roundedUpdateTopAcceleration, topAcceleration)
    }

    private func averageResultantAcceleration(_ values: [MotionValue]) -> Double {
        let (sumX, sumY, sumZ) = values.reduce(into: (0.0, 0.0, 0.0)) { result, value in
            result.0 += value.x
            result.1 += value.y
            result.2 += value.z
        }
        let (averageX, averageY, averageZ) = (
            sumX / Double(values.count), sumY / Double(values.count), sumZ / Double(values.count)
        )

        return sqrt(
            pow(averageX, 2)
                + pow(averageY, 2)
                + pow(averageZ, 2)
        )
    }

    private func splitValuesIntoTimeChunks(
        _ values: [MotionValue],
        invterval: TimeInterval = 0.25
    ) -> [Date: [MotionValue]] {
        let sortedValues = values.sorted { $0.timestamp < $1.timestamp }

        guard let startTime = sortedValues.first?.timestamp else {
            return [:]
        }

        return sortedValues.reduce(into: [Date: [MotionValue]]()) { result, value in
            let elapsedInterval = value.timestamp.timeIntervalSince(startTime)

            // rounded down
            let numberOfIntervalsSinceStartTime = floor(elapsedInterval / invterval)

            let chunkStartTime = startTime.addingTimeInterval(
                numberOfIntervalsSinceStartTime * invterval
            )

            result[chunkStartTime, default: []].append(value)
        }
    }
}
