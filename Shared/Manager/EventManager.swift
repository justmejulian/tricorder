//
//  EventManager.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import OSLog

protocol EventManaging: Actor {
    func register(
        key: EventListenerKey,
        handleData: @escaping @Sendable (_ data: Sendable) async throws -> Data?
    )
    func register(
        key: EventListenerKey,
        handleData: @escaping @Sendable (_ data: Sendable) throws -> Void
    )
    func trigger(key: EventListenerKey, data: Sendable) async throws -> Data?
    func trigger(key: EventListenerKey, data: Sendable) async
    func reset()
}

actor EventManager: EventManaging {
    static let shared = EventManager()

    private var listeners: [EventListenerKey: AsyncEventHandler] = [:]

    func register(
        key: EventListenerKey,
        handleData: @escaping @Sendable (_ data: Sendable) async throws -> Data?  // todo make sendable?
    ) {
        // todo: check if already exists
        listeners[key] = handleData

    }

    func register(
        key: EventListenerKey,
        handleData: @escaping @Sendable (_ data: Sendable) throws -> Void
    ) {

        self.register(
            key: key,
            handleData: { data in
                try handleData(data)
                return nil
            }
        )
    }
    func trigger(key: EventListenerKey, data: Sendable) async throws -> Data? {
        guard let listener = listeners[key] else {
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

    func reset() {
        listeners.removeAll()
    }
}

enum EventManagerError: LocalizedError {
    case noListenerFound

    var errorDescription: String? {
        switch self {
        case .noListenerFound:
            return
                "No event listener found. Ensure that a listener is registered before emitting events."
        }
    }
}

// todo add types of data
enum EventListenerKey: String, CaseIterable {
    case startedRecording
    case endedRecroding
    case companionStartedRecording
    case sessionStateChanged
    case collectedSensorValues
    case collectedDistance
    case receivedData
    case receivedWorkoutData
    case receivedFileData
}

typealias EventHandler = (_ data: Sendable) throws -> Void
typealias AsyncEventHandler = (_ data: Sendable) async throws -> Data?
