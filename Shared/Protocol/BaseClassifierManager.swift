//
//  BaseClassifierManager.swift
//
//  Created by Julian Visser on 05.12.2024.
//

import Foundation

@MainActor
protocol BaseClassifierManager: ObservableObject {
    var motionManager: MotionObservableValueManager { get }
    var distanceManager: ObservableValueManager<DistanceValue> { get }
    var heartRateManager: ObservableValueManager<StatisticValue> { get }

    func reset() async
    func update(_ sensor: Sensor) async
}
