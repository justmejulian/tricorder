//
//  tricorderApp.swift
//  tricorder Watch App
//
//  Created by Julian Visser on 01.10.2024.
//

import SwiftUI

@main
struct tricorder_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let eventManager = EventManager.shared
    private let recordingManager = RecordingManager()

    @SceneBuilder var body: some Scene {
        WindowGroup {
            PagingView()
                .environmentObject(recordingManager)
        }
    }
}
