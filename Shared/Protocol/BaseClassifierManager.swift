//
//  BaseClassifierManager.swift
//
//  Created by Julian Visser on 05.12.2024.
//

import Foundation

@MainActor
protocol BaseClassifierManager: ObservableObject {
    var motionManager: MotionManager { get }
    var distanceManager: ObservableValueManager<DistanceValue> { get }
    var heartRateManager: ObservableValueManager<StatisticValue> { get }

    func reset()
    func update(_ sensor: Sensor)
}
