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

    @Published
    var isLastDidReceiveDataDateTooRecent = false

    private let debouncer = Debouncer(duration: .seconds(5))  // Wait for last packages
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
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        lastDidReceiveDataDate = Date()
        Task {
            await updateIsLastDidReceiveDataDateTooRecent()
        }
    }

    func updateIsLastDidReceiveDataDateTooRecent() async {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        Logger.shared.debug("Setting lastDidReceiveDataDateTooRecent to true")
        isLastDidReceiveDataDateTooRecent = true
        guard await debouncer.sleep() else { return }
        Logger.shared.debug("Setting lastDidReceiveDataDateTooRecent to false")
        guard let lastDidReceiveDataDate else {
            isLastDidReceiveDataDateTooRecent = true
            return
        }
        let timeInterval = lastDidReceiveDataDate.timeIntervalSinceNow
        // More that 5s ago
        isLastDidReceiveDataDateTooRecent = timeInterval.isLess(than: -5)
    }
}
