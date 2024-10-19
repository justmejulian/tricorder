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
  private let workoutManager = WorkoutManager.shared
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(workoutManager)
    }
  }
}
