//
//  NearbyInteractionManager.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Combine
import NearbyInteraction
import OSLog

actor NearbyInteractionManager: NSObject {
    let eventManager = EventManager.shared

    private var session: NISession?

    private var config: NINearbyPeerConfiguration?
}

extension NearbyInteractionManager {
    func setDiscoveryToken(_ token: NIDiscoveryToken) throws {
        // todo can i get rid of this? init?
        if session == nil {
            initializeNISession()
        }

        self.config = NINearbyPeerConfiguration(peerToken: token)
    }

    func setDiscoveryToken(_ tokenData: Data) throws {

        guard
            let token = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NIDiscoveryToken.self,
                from: tokenData
            )
        else {
            throw NearbyInteractionManagerError.decodingError
        }

        try setDiscoveryToken(token)
    }

    func getDiscoveryTokenData() throws -> Data {

        // todo can i get rid of this? init?
        if session == nil {
            initializeNISession()
        }

        guard let token = session?.discoveryToken else {
            throw NearbyInteractionManagerError.noDiscoveryTokenAvailable
        }

        return try NSKeyedArchiver.archivedData(
            withRootObject: token,
            requiringSecureCoding: true
        )
    }
}

extension NearbyInteractionManager {
    func start() {
        Logger.shared.info("Starting NearbyInteractionManager")

        guard let config = config else {
            Logger.shared.error(
                "NearbyInteractionManager: No config set. Did you call setDiscoveryToken?"
            )
            return
        }

        session?.run(config)
    }

    func stop() {

        // todo: maybe deinitializeNISession?
        session?.pause()

        deinitializeNISession()
    }

    private func initializeNISession() {

        let isSupported = NISession.deviceCapabilities
            .supportsPreciseDistanceMeasurement
        guard isSupported else {
            // todo throw error
            Logger.shared.error(
                "precise distance measurement is not supported"
            )
            return
        }

        // todo: check if supported and

        session = NISession()
        session?.delegate = self
        session?.delegateQueue = DispatchQueue.main
    }

    private func deinitializeNISession() {

        Logger.shared.info("invalidating and deinitializing the NISession")

        session?.invalidate()
        session = nil
    }
}

// MARK: - NISessionDelegate
extension NearbyInteractionManager: NISessionDelegate {
    nonisolated func sessionWasSuspended(_ session: NISession) {

        Logger.shared.info("NISession was suspended")
    }

    nonisolated func sessionSuspensionEnded(_ session: NISession) {

        Logger.shared.info("NISession suspension ended")
    }

    nonisolated func session(
        _ session: NISession,
        didInvalidateWith error: Error
    ) {
        Logger.shared.error(
            "NISession did invalidate with error: \(error.localizedDescription)"
        )
    }

    nonisolated func session(
        _ session: NISession,
        didUpdate nearbyObjects: [NINearbyObject]
    ) {

        let timestamp = Date()
        // todo: I guess always should just be one so I can take first
        // if let object = nearbyObjects.first, let distance = object.distance {

        if nearbyObjects.isEmpty {
            Logger.shared.error("NISession did not receive any nearby objects")
            return
        }

        if nearbyObjects.count > 1 {
            Logger.shared.error("NISession received more than one nearby object")
        }

        let firstObject = nearbyObjects.first!

        let value: Double = Double(firstObject.distance ?? 0)

        Task {
            await eventManager.trigger(
                key: .collectedDistance,
                data: DistanceValue(value: value, timestamp: timestamp)
            ) as Void
        }
    }

    nonisolated func session(
        _ session: NISession,
        didRemove nearbyObjects: [NINearbyObject],
        reason: NINearbyObject.RemovalReason
    ) {

        switch reason {
        case .peerEnded:
            Logger.shared.info("NISession remote peer ended the connection")
            Task {
                await deinitializeNISession()
            }
        case .timeout:
            Logger.shared.error("NISession peer connection timed out")
        default:
            Logger.shared.error("NISession disconnected from peer for an unknown reason")
        }
    }
}

enum NearbyInteractionManagerError: Error {
    case noDiscoveryTokenAvailable
    case encodingError
    case decodingError
}
