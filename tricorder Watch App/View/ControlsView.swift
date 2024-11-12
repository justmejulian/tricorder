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

    @State private var error: Error?
    @State private var showAlert: Bool = false

    var body: some View {
        var errorMessage: String {
            if let localizedDescription = error?.localizedDescription {
                return localizedDescription
            }

            return "Something went wrong starting the workout."
        }

        VStack {
            Button {
                startWorkout()
            } label: {
                Label("Start", systemImage: "play.fill")
                    .labelStyle(WatchMenuLabelStyle())
            }
            .disabled(recordingManager.recordingState.isActive)
            .tint(.green)

            Button {
                stopWorkout()
            } label: {
                Label("End", systemImage: "xmark")
                    .labelStyle(WatchMenuLabelStyle())
            }
            .tint(.red)
            .disabled(!recordingManager.recordingState.isActive)
        }
        .alert(errorMessage, isPresented: $showAlert) {
            Button("Dismiss", role: .cancel) {
                reset()
                stopWorkout()
            }
        }
    }
}
extension ControlsView {
    struct WatchMenuLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.icon
                    .frame(width: 30)
                configuration.title
                Spacer()
            }
        }
    }
}

extension ControlsView {
    private func reset() {
        self.error = nil
        self.showAlert = false
    }
    private func stopWorkout() {
        recordingManager.workoutManager.session?.stopActivity(
            with: .now
        )
    }
    private func startWorkout() {
        Task {
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .functionalStrengthTraining
            configuration.locationType = .indoor

            do {
                try await recordingManager.startRecording(
                    workoutConfiguration: configuration
                )
            } catch {
                Logger.shared.error("Error starting workout: \(error)")
                self.error = error
                self.showAlert = true
            }
        }
    }
}
