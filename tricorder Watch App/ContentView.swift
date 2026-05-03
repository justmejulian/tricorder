//
//  ContentView.swift
//  tricorder Watch App
//
//  Created by Julian Visser on 01.10.2024.
//

import SwiftUI
import WorkoutCore

struct ContentView: View {
    @Environment(\.workoutManager) private var workoutManager

    var body: some View {
        VStack(spacing: 16) {
            statusView
            Button(action: handleButton) {
                Text(state == .idle ? "Start" : "Stop")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(state == .idle ? .green : .red)
        }
        .padding()
    }

    private var state: WorkoutState { workoutManager?.state ?? .idle }

    @ViewBuilder
    private var statusView: some View {
        switch state {
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
        switch state {
        case .idle:
            Task { try? await workoutManager?.startWorkout() }
        case .active:
            workoutManager?.stopWorkout()
        }
    }

}

#Preview {
    ContentView()
        .environment(\.workoutManager, MockWorkoutManager())
}
