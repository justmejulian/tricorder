//
//  RecordingManager.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import os

actor RecordingManager: ObservableObject {
    let eventManager = EventManager.shared

    @MainActor
    var workoutManager = WorkoutManager()

    #if os(watchOS)
    var motionManager = MotionManager()
    #endif
    
    init() {
        Task {
            await registerListeners()
        }
    }

    func sendData(key: String, data: Data) async {
        do {
            let dataObject = try DataObjectManager().encode(
                key: key, data: data)
            await workoutManager.sendData(dataObject, retryCount: 0)
        } catch {
            Logger.shared.error("Could not encode data for key : \(key)")
        }
    }

}
