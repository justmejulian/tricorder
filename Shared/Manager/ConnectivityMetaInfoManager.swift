//
//  OpenConnectionManager.swift
//  tricorder
//
//  Created by Julian Visser on 15.11.2024.
//

import Foundation
import OSLog

@MainActor
class ConnectivityMetaInfoManager: ObservableObject {
    @Published
    var openSendConnectionsCount = 0

    var hasOpenSendConnections: Bool {
        openSendConnectionsCount > 0
    }

    var lastDidReceiveDataDate: Date?

    @Published
    var isLastDidReceiveDataDateTooRecent = false

    private let debouncer = Debouncer(duration: .seconds(10))  // Wait for last packages
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
        updateIsLastDidReceiveDataDateTooRecent()
    }

    func updateIsLastDidReceiveDataDateTooRecent() {
        Task {
            isLastDidReceiveDataDateTooRecent = true

            // Only continue if no more updates
            guard await debouncer.sleep() else { return }

            isLastDidReceiveDataDateTooRecent = false
        }
    }
}
