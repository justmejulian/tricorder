//
//  SessionManager+iOS.swift
//  tricorder
//
//  Created by Julian Visser on 31.10.2024.
//

import Foundation
import HealthKit
import os

extension SessionManager {
    /**
     Consume the session state change from the async stream to update sessionState and finish the workout.
     */
    func consumeSessionStateChange(_ change: SessionSateChange) async {
        sessionState = change.newState
    }

    func handleReceivedData(_ data: Data) throws {
        Logger.shared.info("\(#function) called: \(data.debugDescription)")
        let dataObject = try DataObjectManager().decode(data)
        // todo call others
    }

    func workoutSessionMirroringStartHandler(mirroredSession: HKWorkoutSession)
    {
        self.reset()
        self.session = mirroredSession
        self.session?.delegate = self
        Logger.shared.log(
            "Start mirroring remote session: \(mirroredSession)")
    }
    
    func resetRest() {
        
    }

}
