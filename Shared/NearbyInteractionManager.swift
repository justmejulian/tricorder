/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The helper class that handles the transfer of discovery tokens between peers
         and maintains the Nearby Interaction session.
*/

import Combine
import NearbyInteraction
import WatchConnectivity
import os

// todo: can this be done in the backround?
//@MainActor
class NearbyInteractionManager: NSObject, ObservableObject {
    
    // todo: should this be shared?

    /// The distance to the nearby object (the paired device) in meters.
    @Published var distance: Measurement<UnitLength>?

    private var didSendDiscoveryToken: Bool = false

    private var session: NISession?
    
    //todo move this into init
    func start() {
        initializeNISession()
    }

    func stop() {
        session?.pause()
        reset()
    }

    private func reset() {
        distance = nil
        // todo dedeinitialize
    }

    private func initializeNISession() {
        Logger.shared.info("initializing the NISession")

        let isSupported = NISession.deviceCapabilities
            .supportsPreciseDistanceMeasurement
        guard isSupported else {
            // todo throw error
            Logger.shared.error(
                "precise distance measurement is not supported")
            return
        }

        session = NISession()
        session?.delegate = self
        session?.delegateQueue = DispatchQueue.main
    }

    private func deinitializeNISession() {
        Logger.shared.info("invalidating and deinitializing the NISession")
        session?.invalidate()
        session = nil
        didSendDiscoveryToken = false
    }

    private func restartNISession() {
        Logger.shared.info("restarting the NISession")
        if let config = session?.configuration {
            session?.run(config)
        }
    }

    /// Send the local discovery token to the paired device
    private func sendDiscoveryToken() {
        
        Logger.shared.info("\(#function)")
        // todo: make sure initialized
        
        guard let token = session?.discoveryToken else {
            Logger.shared.info("NIDiscoveryToken not available")
            return
        }

        guard
            let tokenData = try? NSKeyedArchiver.archivedData(
                withRootObject: token, requiringSecureCoding: true)
        else {
            Logger.shared.error("failed to encode NIDiscoveryToken")
            return
        }

        do {
            Logger.shared.info("NIDiscoveryToken \(token) sent to counterpart")
            didSendDiscoveryToken = true
        } catch let error {
            Logger.shared.error(
                "failed to send NIDiscoveryToken: \(error.localizedDescription)"
            )
        }
    }

    /// When a discovery token is received, run the session
    func didReceiveDiscoveryToken(_ tokenData: Data) {
        Logger.shared.info("\(#function): \(tokenData.debugDescription)")
        if let token = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NIDiscoveryToken.self, from: tokenData)
        {
            if session == nil { initializeNISession() }
            //todo sendDiscoveryToken
            if !didSendDiscoveryToken { sendDiscoveryToken() }
            
            Logger.shared.info("running NISession with peer token: \(token)")
            let config = NINearbyPeerConfiguration(peerToken: token)
            session?.run(config)
        } else {
            Logger.shared.error("failed to decode NIDiscoveryToken")
        }
    }
    
    func getTokenData() -> Data? {
        guard let token = session?.discoveryToken else {
            os_log("NIDiscoveryToken not available")
            return nil
        }
        
        guard let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
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

    nonisolated func session(_ session: NISession, didInvalidateWith error: Error) {
        Logger.shared.error(
            "NISession did invalidate with error: \(error.localizedDescription)"
        )
        distance = nil
    }

    nonisolated func session(
        _ session: NISession, didUpdate nearbyObjects: [NINearbyObject]
    ) {
        if let object = nearbyObjects.first, let distance = object.distance {
            Logger.shared.info("object distance: \(distance) meters")
            self.distance = Measurement(value: Double(distance), unit: .meters)
        }
    }

    nonisolated func session(
        _ session: NISession, didRemove nearbyObjects: [NINearbyObject],
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
