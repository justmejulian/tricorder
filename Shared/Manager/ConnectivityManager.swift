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
            do {
                let _ = try await eventManager.trigger(
                    key: .receivedData,
                    data: messageData
                )
            } catch {
                Logger.shared.error("Error trying to trigger event: \(error.localizedDescription)")
            }
        }
    }
}

extension ConnectivityManager {
    func sendCodable(key: String, data: Data) throws {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        try sendCodable(key: key, data: data, replyHandler: nil)
    }

    // todo convert to asyn await
    func sendCodable(key: String, data: Data, replyHandler: ((Data) -> Void)?) throws {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        let dataObject = try SendDataObjectManager().encode(
            key: key,
            data: data
        )

        self.session.sendMessageData(
            dataObject,
            replyHandler: replyHandler,
            errorHandler: { (error) in
                Logger.shared.error("Error sending: \(key) \(error.localizedDescription)")
            }
        )
    }
}
