//
//  ConnectivityManager.swift
//  tricorder
//
//  Created by Julian Visser on 07.11.2024.
//

import Foundation
import OSLog
@preconcurrency import WatchConnectivity

protocol WCSessionProtocol: AnyObject, Sendable {
    var isReachable: Bool { get }
    var delegate: WCSessionDelegate? { get set }

    func activate()
    func sendMessageData(
        _ data: Data,
        replyHandler: ((Data) -> Void)?,
        errorHandler: ((Error) -> Void)?
    )
    func transferFile(_ file: URL, metadata: [String: Any]?) -> WCSessionFileTransfer
}

extension WCSession: WCSessionProtocol, @unchecked Sendable {}

protocol ConnectivityManaging: Actor {
    @MainActor var connectivityMetaInfoManager: ConnectivityMetaInfoManager { get }

    func activate()
    func sendDataArray(key: String, dataArray: [Data]) async throws
    func sendData(key: String, data: Data) async throws
    func sendData(key: String, data: Data) async throws -> Data?
    func sendDataAsFile(_ data: Data) async throws
    func increaseFailedSendCount()
    func getFailedSendCount() -> Int
    func reset() async
}

actor ConnectivityManager: NSObject, WCSessionDelegate, ConnectivityManaging {
    let eventManager: any EventManaging

    private var session: WCSessionProtocol

    private var failedSendCount: Int = 0

    // property whose initial value is not calculated until the first time it’s called
    @MainActor
    private var connectivityMetaInfoManagerStorage: ConnectivityMetaInfoManager?

    override init() {
        // Logger.shared.debug("creating ConnectivityManager on Thread \(Thread.current)")

        self.eventManager = EventManager.shared
        self.session = WCSession.default
        super.init()
    }

    init(
        session: WCSessionProtocol,
        eventManager: any EventManaging = EventManager.shared
    ) {
        self.eventManager = eventManager
        self.session = session
        super.init()
    }

    func increaseFailedSendCount() {
        self.failedSendCount += 1
    }

    func getFailedSendCount() -> Int {
        return failedSendCount
    }

    func activate() {
        self.session.delegate = self
        self.session.activate()
    }

    @MainActor
    var connectivityMetaInfoManager: ConnectivityMetaInfoManager {
        if let connectivityMetaInfoManagerStorage {
            return connectivityMetaInfoManagerStorage
        }

        let manager = ConnectivityMetaInfoManager()
        connectivityMetaInfoManagerStorage = manager
        return manager
    }

    @MainActor
    func setConnectivityMetaInfoManager(
        _ manager: ConnectivityMetaInfoManager
    ) {
        connectivityMetaInfoManagerStorage = manager
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

    nonisolated func session(
        _ session: WCSession,
        didReceive file: WCSessionFile
    ) {
        let receivedFileURL = file.fileURL

        do {
            let fileData = try Data(contentsOf: receivedFileURL)

            Task {
                await eventManager.trigger(
                    key: .receivedFileData,
                    data: fileData
                ) as Void
            }

        } catch {
            Logger.shared.error("Failed to read file: \(error)")
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

    func sendDataAsFile(_ data: Data) async throws {
        if !self.session.isReachable {
            throw ConnectivityError.notReachable
        }

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("tmp-file-send")
        try data.write(to: fileURL)
        try await sendFileData(fileURL)
    }

    private func sendMessageData(_ data: Data) async throws -> Data? {

        if !self.session.isReachable {
            throw ConnectivityError.notReachable
        }

        Task {
            await connectivityMetaInfoManager.increaseOpenSendConnectionsCount()
        }

        let session = self.session

        return try await withCheckedThrowingContinuation({
            @Sendable continuation in
            session.sendMessageData(
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
        })
    }

    private func sendFileData(_ url: URL) async throws {
        if !self.session.isReachable {
            throw ConnectivityError.notReachable
        }

        Task {
            await connectivityMetaInfoManager.increaseOpenSendConnectionsCount()
        }

        try await withCheckedThrowingContinuation {
            continuation in

            let fileTransfer = self.session.transferFile(url, metadata: nil)

            // Observe the progress
            let observation = fileTransfer.progress.observe(\.isFinished, options: [.new]) {
                progress,
                _ in
                if progress.isFinished {
                    // Resume the continuation when the transfer finishes
                    continuation.resume()

                    // Decrement the connections count
                    Task {
                        await self.connectivityMetaInfoManager.decreaseOpenSendConnectionsCount()
                    }
                }
            }

            // Cleanup to ensure continuation is resumed in all cases
            Task {
                try await Task.sleep(nanoseconds: 60 * 1_000_000_000)  // 30 seconds timeout
                if !fileTransfer.progress.isFinished {
                    // Timeout fallback: Ensure continuation is resumed
                    continuation.resume(throwing: ConnectivityError.timeout)

                    // Decrement the connections count
                    await self.connectivityMetaInfoManager.decreaseOpenSendConnectionsCount()
                }

                // Invalidate observation after the timeout
                observation.invalidate()
            }
        }
    }
}

enum ConnectivityError: LocalizedError {
    case notReachable
    case timeout

    var errorDescription: String? {
        switch self {
        case .notReachable:
            return "The Watch is not reachable."
        case .timeout:
            return "The request timed out."
        }
    }
}
