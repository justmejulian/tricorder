//
//  EventManager.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import os

actor EventManager {
    static let shared = RecordingManager()
    
    static var listeners: [EventListenerKey: EventHandler] = [:]
    func register(key: EventListenerKey, handleData: @escaping @Sendable (_ data: Sendable) throws -> Void) {
        
        EventManager.listeners[key] = handleData
    }
        
    func trigger(key: EventListenerKey, data: Sendable) {
        guard var listener = EventManager.listeners[key] else {
            Logger.shared.error("No listener found for \(key.rawValue)")
            return
        }
        
        do {
            try listener(data)
        } catch {
            Logger.shared.error("Listener for \(key.rawValue) threw error: \(error)")
        }
    }
    
}

enum EventListenerKey: String, CaseIterable {
    case startRecording
}

typealias EventHandler = (_ data: Sendable) throws -> Void
