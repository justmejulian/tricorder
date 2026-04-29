//
//  ContentView.swift
//  tricorder Watch App
//
//  Created by Julian Visser on 01.10.2024.
//

import SwiftUI

struct ContentView: View {
    @Environment(WatchWorkoutManager.self) private var workoutManager

    var body: some View {
        VStack(spacing: 16) {
            statusView
            Button(action: handleButton) {
                Text(workoutManager.state == .idle ? "Start" : "Stop")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(workoutManager.state == .idle ? .green : .red)
        }
        .padding()
    }

    @ViewBuilder
    private var statusView: some View {
        switch workoutManager.state {
        case .idle:
            Text("Ready")
                .foregroundStyle(.secondary)
        case .active(let startDate):
            TimelineView(.periodic(from: startDate, by: 1)) { context in
                Text(elapsedString(from: startDate, to: context.date))
                    .monospacedDigit()
                    .font(.title2)
            }
        }
    }

    private func handleButton() {
        switch workoutManager.state {
        case .idle:
            Task { try? await workoutManager.startWorkout() }
        case .active:
            workoutManager.stopWorkout()
        }
    }

}

#Preview {
    ContentView()
        .environment(WatchWorkoutManager())
}
