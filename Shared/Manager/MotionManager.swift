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
    var motionValues: [MotionValue] = []

    init() {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")
    }
}

extension MotionManager {
    func reset() {
        motionValues = []
    }

    func updateMotionValues(_ values: [MotionValue]) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        motionValues.append(contentsOf: values)
    }
}
