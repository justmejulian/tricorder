//
//  NearbyInteractionManager.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Combine
import NearbyInteraction
import os

actor NearbyInteractionManager: NSObject {
    let eventManager = EventManager.shared

    private var session: NISession?

    private var config: NINearbyPeerConfiguration?
}

extension NearbyInteractionManager {
    func setDiscoveryToken(_ tokenData: Data) throws {
        Logger.shared.debug("NearbyInteractionManager \(#function) called on Thread \(Thread.current)")

        guard
            let token = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NIDiscoveryToken.self,
                from: tokenData
            )
        else {
            throw NearbyInteractionManagerError.decodingError
        }

        // todo can i get rid of this? init?
        if session == nil {
            initializeNISession()
        }

        self.config = NINearbyPeerConfiguration(peerToken: token)
    }

    func getDiscoveryToken() throws -> Data {
        Logger.shared.debug("NearbyInteractionManager \(#function) called on Thread \(Thread.current)")

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
        Logger.shared.info("Start NearbyInteractionManager")
        Logger.shared.debug("NearbyInteractionManager start called on Thread \(Thread.current)")

        guard let config = config else {
            Logger.shared.error("No config set. Did you call setDiscoveryToken?")
            return
        }

        session?.run(config)
    }

    func stop() {
        Logger.shared.debug("NearbyInteractionManager stop called on Thread \(Thread.current)")

        // todo: maybe deinitializeNISession?
        session?.pause()

        deinitializeNISession()
    }

    private func initializeNISession() {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

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
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        Logger.shared.info("invalidating and deinitializing the NISession")
        session?.invalidate()
        session = nil
    }
}

// MARK: - NISessionDelegate
extension NearbyInteractionManager: NISessionDelegate {
    nonisolated func sessionWasSuspended(_ session: NISession) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")
        Logger.shared.info("NISession was suspended")
    }

    nonisolated func sessionSuspensionEnded(_ session: NISession) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")
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
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        if let object = nearbyObjects.first, let distance = object.distance {
            Task {
                try await eventManager.trigger(
                    key: .collectedDistance,
                    data: distance
                )
            }
        }
    }

    nonisolated func session(
        _ session: NISession,
        didRemove nearbyObjects: [NINearbyObject],
        reason: NINearbyObject.RemovalReason
    ) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

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
