/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout controls.
*/

import HealthKit
import SwiftUI
import os

struct ControlsView: View {
    @EnvironmentObject var recordingManager: RecordingManager

    var body: some View {
        VStack {
            Button {
                startWorkout()
            } label: {
                ButtonLabel(title: "Start", systemImage: "figure.outdoor.cycle")
            }
            .disabled(recordingManager.workoutManager.sessionState.isActive)
            .tint(.green)

            Button {
                recordingManager.workoutManager.sessionState == .running
                    ? recordingManager.workoutManager.session?.pause()
                    : recordingManager.workoutManager.session?.resume()
            } label: {
                let title =
                    recordingManager.workoutManager.sessionState == .running
                    ? "Pause" : "Resume"
                let systemImage =
                    recordingManager.workoutManager.sessionState == .running
                    ? "pause" : "play"
                ButtonLabel(title: title, systemImage: systemImage)
            }
            .disabled(!recordingManager.workoutManager.sessionState.isActive)
            .tint(.blue)

            Button {
                recordingManager.workoutManager.session?.stopActivity(
                    with: .now)
            } label: {
                ButtonLabel(title: "End", systemImage: "xmark")
            }
            .tint(.red)
            .disabled(!recordingManager.workoutManager.sessionState.isActive)
        }
    }

    private func startWorkout() {
        Task {
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .functionalStrengthTraining
            configuration.locationType = .indoor
            await recordingManager.startRecording(
                workoutConfiguration: configuration)
        }
    }
}
