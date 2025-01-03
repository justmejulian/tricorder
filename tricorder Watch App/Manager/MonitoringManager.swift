//
//  MonitoringManager.swift
//  tricorder
//
//  Created by Julian Visser on 09.11.2024.
//

import Foundation
import OSLog

@MainActor
class MonitoringManager: ObservableObject {
    @Published var updateSendSuccess: [Success] = []

    @Published var updateSendSuccessTrueCount: Int = 0

    var updateSendSuccessCount: Int {
        return updateSendSuccess.count
    }

    var last10UpdateSendSuccess: [Success] {
        return updateSendSuccess.suffix(10)
    }

    func reset() {

        self.updateSendSuccess = []
        self.updateSendSuccessTrueCount = 0
    }

    func addUpdateSendSuccess(_ success: Bool) {

        if success {
            updateSendSuccessTrueCount += 1
        }

        updateSendSuccess.append(Success(state: success))
    }
}

extension MonitoringManager {
    struct Success: Identifiable {
        var id: UUID = .init()
        var state: Bool
    }
}
