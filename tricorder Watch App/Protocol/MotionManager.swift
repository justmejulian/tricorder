//
//  MotionManager.swift
//
//  Created by Julian Visser on 10.12.2024.
//

@preconcurrency import CoreMotion
import Foundation
import OSLog

protocol MotionManager: Actor {
    func startUpdates(recordingStart: Date) async throws
    func stopUpdates() async
    var handleUpdate: @Sendable (_ sensor: Sensor) -> Void { get }
}

extension MotionManager {

}
