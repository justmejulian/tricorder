//
//  ConnectivityManager.swift
//  tricorder
//
//  Created by Julian Visser on 07.11.2024.
//

import Foundation
import os
import WatchConnectivity

extension ConnectivityManager {
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Logger.shared.debug("Session WatchState Did Change")
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Logger.shared.debug("Session Did Become Inactive")
    }
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Logger.shared.debug("Session Did Become Deactivate")
    }
}
