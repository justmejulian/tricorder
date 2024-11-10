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
    @Published var motionUpdateSendSuccess: [Success] = []

    @Published var motionUpdateSendSuccessTrueCount: Int = 0

    var motionUpdateSendSuccessCount: Int {
        return motionUpdateSendSuccess.count
    }

    var last10MotionUpdateSendSuccess: [Success] {
        return motionUpdateSendSuccess.suffix(10)
    }

    func reset() {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")
        self.motionUpdateSendSuccess = []
        self.motionUpdateSendSuccessTrueCount = 0
    }

    func addMotioUpdateSendSuccess(_ success: Bool) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        if success {
            motionUpdateSendSuccessTrueCount += 1
        }

        motionUpdateSendSuccess.append(Success(state: success))
    }
}

extension MonitoringManager {
    struct Success: Identifiable {
        var id: UUID = .init()
        var state: Bool
    }
}
