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
import WatchConnectivity

actor ConnectivityManager: NSObject, WCSessionDelegate {
    let eventManager = EventManager.shared

    private var session: WCSession = .default

    override init() {
        Logger.shared.debug("Creating ConnectivityManager")

        super.init()

        self.session.delegate = self
        self.session.activate()
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
        replyHandler: @escaping (Data) -> Void
    ) {
        Logger.shared.debug("\(#function) with replyHandler called on Thread \(Thread.current)")

        Task {
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
                Logger.shared.error("Error trying to trigger event: \(error.localizedDescription)")

                do {
                    replyHandler(try JSONEncoder().encode(["error": error.localizedDescription]))
                } catch {
                    Logger.shared.error("Failed to reply")
                }
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessageData messageData: Data
    ) {
        Logger.shared.debug("\(#function) no replyHandler called on Thread \(Thread.current)")

        Task {
            await eventManager.trigger(
                key: .receivedData,
                data: messageData
            ) as Void
        }
    }
}

extension ConnectivityManager {
    // needs to be called with 'as Void'
    func sendCodable(key: String, data: Data) throws {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        let dataObject = try SendDataObjectManager().encode(
            key: key,
            data: data
        )

        sendMessageData(dataObject)
    }

    private func sendMessageData(_ data: Data) {
        self.session.sendMessageData(
            data,
            replyHandler: nil
        )
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
        return try await withCheckedThrowingContinuation({
            continuation in
            self.session.sendMessageData(
                data,
                replyHandler: { data in
                    Logger.shared.debug("connectivityManager.sendMessageData replyHandler called")
                    continuation.resume(returning: data)
                },
                errorHandler: { (error) in
                    continuation.resume(throwing: error)
                }
            )
        })
    }
}
