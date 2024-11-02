//
//  RecordingManager.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import SwiftUICore
import os

actor RecordingManager: ObservableObject {
    let eventManager = EventManager.shared

    @MainActor
    @ObservedObject  // To Propagate changes
    var workoutManager = WorkoutManager()

    var nearbyInteractionManager = NearbyInteractionManager()

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

extension RecordingManager {
    func sendNIDiscoveryToken() async {
        if nearbyInteractionManager.didSendDiscoveryToken {
            return
        }
        
        do {
            let discoveryToken =
                try nearbyInteractionManager.getDiscoveryToken()
                await sendData(key: "discoveryToken", data: discoveryToken)

                // todo: use setter
                nearbyInteractionManager.didSendDiscoveryToken = true
        } catch {
            Logger.shared.error("Could not send discovery token: \(error)")
        }
    }
    
    func handleNIReceiveDiscoveryToken(_ data: Data) {
        Task {
            await sendNIDiscoveryToken()
            nearbyInteractionManager.didReceiveDiscoveryToken(data)
        }
    }
}
