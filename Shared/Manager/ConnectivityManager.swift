//
//  ConnectivityManager.swift
//  tricorder
//
//  Created by Julian Visser on 07.11.2024.
//

import Foundation
import OSLog
import SwiftData
import SwiftUI
@preconcurrency import WatchConnectivity

actor ConnectivityManager: NSObject, WCSessionDelegate {
    let eventManager = EventManager.shared

    private var session: WCSession = .default

    private var failedSendCount: Int = 0

    // property whose initial value is not calculated until the first time it’s called
    @MainActor
    lazy var connectivityMetaInfoManager = ConnectivityMetaInfoManager()

    private var shoudSend: Bool {
        if failedSendCount > 10 {
            return false
        }

        return true
    }

    override init() {
        Logger.shared.debug("Creating ConnectivityManager")

        super.init()

        self.session.delegate = self
        self.session.activate()
    }

    func reset() async {
        self.failedSendCount = 0
        await connectivityMetaInfoManager.reset()
    }
}

extension ConnectivityManager {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        if let error = error {
            Logger.shared.error("Error trying to activate WCSession: \(error.localizedDescription)")
        } else {
            Logger.shared.info("The session has completed activation.")
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessageData messageData: Data,
        // todo not sure if this works
        replyHandler: @Sendable @escaping (Data) -> Void
    ) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        Task {
            await connectivityMetaInfoManager.updateLastDidReceiveDataDate()

            do {
                if let data = try await eventManager.trigger(
                    key: .receivedData,
                    data: messageData
                ) {
                    Logger.shared.debug("EventManager.trigger returned: \(data)")
                    replyHandler(data)
                    return
                }

                replyHandler(try JSONEncoder().encode(["sucess": true]))
            } catch {
                // Todo do I need to replyHandler? or can I throw?
                // maybe catch and thow with better string
                Logger.shared.error("Error trying to trigger event: \(error.localizedDescription)")

                do {
                    replyHandler(try JSONEncoder().encode(["error": error.localizedDescription]))
                } catch {
                    Logger.shared.error("Failed to reply")
                }
            }
        }
    }
}

// MARK: -  ConnectivityManager sendData
//
extension ConnectivityManager {
    // needs to be called with 'as Void'
    func sendCodable(key: String, data: Data) async throws {
        let _ = try await sendCodable(key: key, data: data) as Data?
    }

    func sendCodable(key: String, data: Data) async throws -> Data? {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        let dataObject = try SendDataObjectManager().encode(
            key: key,
            data: data
        )

        return try await sendMessageData(dataObject)
    }

    private func sendMessageData(_ data: Data) async throws -> Data? {

        // stop sending Packets when too many fail
        if !shoudSend {
            throw ConnectivityError.toManyFailed
        }

        Task {
            await connectivityMetaInfoManager.increaseOpenSendConnectionsCount()
        }

        return try await withCheckedThrowingContinuation({
            continuation in
            self.session.sendMessageData(
                data,
                replyHandler: { data in
                    Logger.shared.debug("connectivityManager.sendMessageData replyHandler called")
                    Task {
                        await self.connectivityMetaInfoManager.decreaseOpenSendConnectionsCount()
                    }
                    continuation.resume(returning: data)
                },
                errorHandler: { (error) in
                    self.failedSendCount += 1
                    Task {
                        await self.connectivityMetaInfoManager.decreaseOpenSendConnectionsCount()
                    }
                    continuation.resume(throwing: error)
                }
            )
        })
    }
}

enum ConnectivityError: Error {
    case toManyFailed
}
