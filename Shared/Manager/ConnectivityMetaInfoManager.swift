//
//  OpenConnectionManager.swift
//  tricorder
//
//  Created by Julian Visser on 15.11.2024.
//

import Foundation
import os

@MainActor
class ConnectivityMetaInfoManager: ObservableObject {
    @Published
    var openSendConnectionsCount = 0

    var hasOpenSendConnections: Bool {
        openSendConnectionsCount > 0
    }

    @Published
    var lastDidReceiveDataDate: Date?
}

extension ConnectivityMetaInfoManager {
    func reset() {
        openSendConnectionsCount = 0
        lastDidReceiveDataDate = nil
    }

    func increaseOpenSendConnectionsCount() {
        openSendConnectionsCount += 1
    }

    func decreaseOpenSendConnectionsCount() {
        openSendConnectionsCount -= 1
    }

    func updateLastDidReceiveDataDate() {
        lastDidReceiveDataDate = Date()
    }
}
