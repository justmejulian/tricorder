//
//  RecordingManager+watchOs.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import HealthKit
import os

extension RecordingManager {
    func registerListeners() async {
        await eventManager.register(
            key: .sessionStateChanged, handleData: self.handleSessionStateChange
        )
    }

}

extension RecordingManager {
    @Sendable
    nonisolated func handleSessionStateChange(_ data: Sendable) throws {
        Logger.shared.info("\(#function)")
        
        guard let change = data as? SessionStateChange else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }
        
        Logger.shared.info("Session state changed to \(change.newState.rawValue)")

        Task {
            await workoutManager.setSessionSate(newState: change.newState)
        }
    }
}
