//
//  ConnectivityManager.swift
//  tricorder
//
//  Created by Julian Visser on 07.11.2024.
//

import Foundation
import OSLog
@preconcurrency import WatchConnectivity

actor ConnectivityManager: NSObject, WCSessionDelegate {
    let eventManager = EventManager.shared

    private var session: WCSession = .default

    private var failedSendCount: Int = 0

    // property whose initial value is not calculated until the first time it’s called
    @MainActor
    lazy var connectivityMetaInfoManager = ConnectivityMetaInfoManager()

    override init() {
        // Logger.shared.debug("creating ConnectivityManager on Thread \(Thread.current)")

        super.init()

        self.session.delegate = self
        self.session.activate()
    }

    func increaseFailedSendCount() {
        self.failedSendCount += 1
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
        if let error = error {
            Logger.shared.error("Error trying to activate WCSession: \(error.localizedDescription)")
        } else {
            Logger.shared.info("ConnectivityManager session activated.")
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessageData messageData: Data,
        // todo not sure if this works
        replyHandler: @Sendable @escaping (Data) -> Void
    ) {
        Task {
            await connectivityMetaInfoManager.updateLastDidReceiveDataDate()

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
                // Todo do I need to replyHandler? or can I throw?
                // maybe catch and thow with better string
                Logger.shared.error("Error trying to trigger event: \(error.localizedDescription)")

                do {
                    replyHandler(try JSONEncoder().encode(["error": error.localizedDescription]))
                } catch {
                    Logger.shared.error("Failed to reply with error message.")
                }
            }
        }
    }
}

// MARK: -  ConnectivityManager sendData
//
extension ConnectivityManager {

    func sendDataArray(key: String, dataArray: [Data]) async throws {
        for data in dataArray {
            try await sendData(key: key, data: data) as Void
        }
    }

    // needs to be called with 'as Void'
    func sendData(key: String, data: Data) async throws {
        let _ = try await sendData(key: key, data: data) as Data?
    }

    func sendData(key: String, data: Data) async throws -> Data? {
        let dataObject = try SendDataObjectManager().encode(
            key: key,
            data: data
        )

        return try await sendMessageData(dataObject)
    }

    private func sendMessageData(_ data: Data) async throws -> Data? {

        Task {
            await connectivityMetaInfoManager.increaseOpenSendConnectionsCount()
        }

        return try await withCheckedThrowingContinuation({
            @Sendable continuation in
            Task {
                await self.session.sendMessageData(
                    data,
                    replyHandler: { data in
                        Task {
                            await self.connectivityMetaInfoManager
                                .decreaseOpenSendConnectionsCount()
                            continuation.resume(returning: data)
                        }
                    },
                    errorHandler: { (error) in
                        Task {
                            await self.increaseFailedSendCount()
                            await self.connectivityMetaInfoManager
                                .decreaseOpenSendConnectionsCount()
                            continuation.resume(throwing: error)
                        }
                    }
                )
            }
        })
    }
}

enum ConnectivityError: Error {
    case toManyFailed
}
