//
//  EventManager.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import os

actor EventManager {
    static let shared = EventManager()

    static var listeners: [EventListenerKey: AsyncEventHandler] = [:]

    func register(
        key: EventListenerKey,
        handleData: @escaping @Sendable (_ data: Sendable) async throws -> Data?  // todo make sendable?
    ) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        // todo: check if already exists
        EventManager.listeners[key] = handleData

        Logger.shared.debug("Added EventListener for \(key.rawValue)")
    }

    func register(
        key: EventListenerKey,
        handleData: @escaping @Sendable (_ data: Sendable) throws -> Void
    ) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        self.register(
            key: key,
            handleData: { data in
                try handleData(data)
                return nil
            }
        )
    }
    func trigger(key: EventListenerKey, data: Sendable) async throws -> Data? {
        Logger.shared.debug("key\(key.rawValue) called on Thread \(Thread.current)")

        guard let listener = EventManager.listeners[key] else {
            throw EventManagerError.noListenerFound
        }

        return try await listener(data)
    }

    // todo: make data optional
    // needs to be called with 'as Void'
    func trigger(key: EventListenerKey, data: Sendable) async {
        do {
            let _: Data? = try await trigger(key: key, data: data)
        } catch {
            Logger.shared.error(
                "Failed to trigger Event Listener for \(key.rawValue): \(error.localizedDescription)"
            )
        }
    }
}

enum EventManagerError: Error {
    case noListenerFound
}

enum EventListenerKey: String, CaseIterable {
    case startedRecording
    case endedRecroding
    case companionStartedRecording
    case sessionStateChanged
    case collectedStatistics
    case collectedMotionValues
    case collectedDistance
    case receivedData
    case receivedWorkoutData
}

enum EventManagerHandler: Error {
    case noListenerFound
}

typealias EventHandler = (_ data: Sendable) throws -> Void
typealias AsyncEventHandler = (_ data: Sendable) async throws -> Data?
