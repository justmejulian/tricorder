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
                Label("Start", systemImage: "play.fill")
                    .labelStyle(WatchMenuLabelStyle())
            }
            .disabled(recordingManager.recordingState.isActive)
            .tint(.green)

            Button {
                recordingManager.workoutManager.session?.stopActivity(
                    with: .now
                )
            } label: {
                Label("End", systemImage: "xmark")
                    .labelStyle(WatchMenuLabelStyle())
            }
            .tint(.red)
            .disabled(!recordingManager.recordingState.isActive)
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
    private func startWorkout() {
        Task {
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .functionalStrengthTraining
            configuration.locationType = .indoor
            await recordingManager.startRecording(
                workoutConfiguration: configuration
            )
        }
    }
}
