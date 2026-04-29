//
//  ContentView.swift
//  tricorder
//
//  Created by Julian Visser on 01.10.2024.
//

import SwiftUI

struct ContentView: View {
    @Environment(PhoneWorkoutManager.self) private var workoutManager

    var body: some View {
        VStack(spacing: 32) {
            statusView
            Button(action: handleButton) {
                Text(workoutManager.state == .idle ? "Start Workout" : "Stop Workout")
                    .frame(maxWidth: .infinity)
                    .padding()
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
        .environment(PhoneWorkoutManager())
}
