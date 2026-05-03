//
//  ContentView.swift
//  tricorder
//
//  Created by Julian Visser on 01.10.2024.
//

import SwiftUI
import WorkoutCore

struct ContentView: View {
    @Environment(\.workoutManager) private var workoutManager

    var body: some View {
        VStack(spacing: 32) {
            statusView
            Button(action: handleButton) {
                Text(state == .idle ? "Start Workout" : "Stop Workout")
                    .frame(maxWidth: .infinity)
                    .padding()
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
            Text("No active workout")
                .foregroundStyle(.secondary)
        case .active(let startDate):
            TimelineView(.periodic(from: startDate, by: 1)) { context in
                VStack(spacing: 4) {
                    Text("Active")
                        .foregroundStyle(.green)
                    Text(elapsedString(from: startDate, to: context.date))
                        .monospacedDigit()
                        .font(.largeTitle)
                }
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
