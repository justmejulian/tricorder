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
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        lastDidReceiveDataDate = Date()
        updateIsLastDidReceiveDataDateTooRecent()
    }

    func updateIsLastDidReceiveDataDateTooRecent() {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        Task {
            Logger.shared.debug("Setting lastDidReceiveDataDateTooRecent to true")
            isLastDidReceiveDataDateTooRecent = true
            
            // Only continue if no more updates
            guard await debouncer.sleep() else { return }

            Logger.shared.debug("Setting lastDidReceiveDataDateTooRecent to false")
            isLastDidReceiveDataDateTooRecent = false
        }
    }
}
