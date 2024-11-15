//
//  DistanceManager.swift
//  tricorder
//
//  Created by Julian Visser on 07.11.2024.
//

import Foundation
import os

@MainActor
class DistanceManager: ObservableObject {
    @Published
    var distance: Measurement<UnitLength>?

    func reset() {
        distance = nil
    }
}

extension DistanceManager {
    func setDistance(_ distance: Measurement<UnitLength>) {
        self.distance = distance
    }

    func setDistance(_ distance: Double) {
        self.distance = Measurement(value: Double(distance), unit: .meters)
    }
}
