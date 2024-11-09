//
//  MonitoringManager.swift
//  tricorder
//
//  Created by Julian Visser on 09.11.2024.
//

import Foundation
import os

@MainActor
class MonitoringManager: ObservableObject {
    @Published var motionUpdateSendCount: Int = 0
    @Published var successMotionUpdateSendCount: Int = 0

    func reset() {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")
        self.motionUpdateSendCount = 0
        self.successMotionUpdateSendCount = 0
    }
    
    
    func increaseSuccessMotionUpdateSendCount() {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        successMotionUpdateSendCount += 1
    }

    func increaseMotionUpdateSendCount() {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        motionUpdateSendCount += 1
    }
}
