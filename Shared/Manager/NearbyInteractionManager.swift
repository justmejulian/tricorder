//
//  NearbyInteractionManager.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Combine
import NearbyInteraction
import WatchConnectivity
import os

//@MainActor
class NearbyInteractionManager: NSObject, ObservableObject {
    /// The distance to the nearby object (the paired device) in meters.
    @Published
    var distance: Measurement<UnitLength>?

    var didSendDiscoveryToken: Bool = false
    private var session: NISession?

    override init() {
        super.init()

        initializeNISession()
    }

    // todo: I guess this should be init
    func start() {
        Logger.shared.debug("NearbyInteractionManager start called on Thread \(Thread.current)")

        restartNISession()
    }

    func stop() {
        Logger.shared.debug("NearbyInteractionManager stop called on Thread \(Thread.current)")

        // todo: maybe deinitializeNISession?
        session?.pause()
        reset()
    }

    private func reset() {
        Logger.shared.debug("NearbyInteractionManager reset called on Thread \(Thread.current)")

        distance = nil
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
        didSendDiscoveryToken = false
    }

    private func restartNISession() {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        Logger.shared.info("restarting the NISession")
        if let config = session?.configuration {
            session?.run(config)
        }
    }

    func getDiscoveryToken() throws -> Data {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        guard let token = session?.discoveryToken else {
            throw NearbyInteractionManagerError.noDiscoveryTokenAvailable
        }
        guard
            let tokenData = try? NSKeyedArchiver.archivedData(
                withRootObject: token,
                requiringSecureCoding: true
            )
        else {
            throw NearbyInteractionManagerError.encodingError
        }

        return tokenData
    }

    /// When a discovery token is received, run the session
    func didReceiveDiscoveryToken(_ tokenData: Data) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        if let token = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NIDiscoveryToken.self,
            from: tokenData
        ) {
            if session == nil { initializeNISession() }
            Logger.shared.info("running NISession with peer token: \(token)")
            let config = NINearbyPeerConfiguration(peerToken: token)
            session?.run(config)
        } else {
            Logger.shared.error("failed to decode NIDiscoveryToken")
        }
    }

    func getTokenData() -> Data? {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        guard let token = session?.discoveryToken else {
            os_log("NIDiscoveryToken not available")
            return nil
        }

        guard
            let tokenData = try? NSKeyedArchiver.archivedData(
                withRootObject: token,
                requiringSecureCoding: true
            )
        else {
            os_log("failed to encode NIDiscoveryToken")
            return nil
        }

        return tokenData
    }
}

// MARK: - NISessionDelegate
extension NearbyInteractionManager: NISessionDelegate {
    nonisolated func sessionWasSuspended(_ session: NISession) {
        Logger.shared.info("NISession was suspended")
        distance = nil
    }
    nonisolated func sessionSuspensionEnded(_ session: NISession) {
        Logger.shared.info("NISession suspension ended")
        restartNISession()
    }
    nonisolated func session(
        _ session: NISession,
        didInvalidateWith error: Error
    ) {
        Logger.shared.error(
            "NISession did invalidate with error: \(error.localizedDescription)"
        )
        distance = nil
    }
    nonisolated func session(
        _ session: NISession,
        didUpdate nearbyObjects: [NINearbyObject]
    ) {
        if let object = nearbyObjects.first, let distance = object.distance {
            Logger.shared.info("object distance: \(distance) meters")
            self.distance = Measurement(value: Double(distance), unit: .meters)
        }
    }
    nonisolated func session(
        _ session: NISession,
        didRemove nearbyObjects: [NINearbyObject],
        reason: NINearbyObject.RemovalReason
    ) {
        switch reason {
        case .peerEnded:
            Logger.shared.info("the remote peer ended the connection")
            deinitializeNISession()
        case .timeout:
            Logger.shared.error("peer connection timed out")
            restartNISession()
        default:
            Logger.shared.error("disconnected from peer for an unknown reason")
        }
        distance = nil
    }
}

enum NearbyInteractionManagerError: Error {
    case noDiscoveryTokenAvailable
    case encodingError
}
