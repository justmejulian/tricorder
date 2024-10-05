//
//  ContentView.swift
//  tricorder
//
//  Created by Julian Visser on 01.10.2024.
//

import os
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    private func startCyclingOnWatch() {
        Task {
            do {
                try await workoutManager.startWatchWorkout()
            } catch {
                Logger.shared.log("Failed to start cycling on the paired watch.")
            }
        }
    }

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button {
                startCyclingOnWatch()
            } label: {
                Label("Start Cycling", systemImage: "arrow.2.circlepath.circle")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
