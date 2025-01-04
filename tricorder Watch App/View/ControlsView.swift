/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout controls.
*/

import HealthKit
import OSLog
import SwiftUI

struct ControlsView: View {
    @EnvironmentObject var recordingManager: RecordingManager

    @ObservedObject
    var connectivityMetaInfoManager: ConnectivityMetaInfoManager

    @State private var error: Error?
    @State private var showAlert: Bool = false
    @State private var loading: Bool = false

    var body: some View {
        var errorMessage: String {
            if let localizedDescription = error?.localizedDescription {
                return localizedDescription
            }

            return "Something went wrong starting the workout."
        }

        let isSending = connectivityMetaInfoManager.hasOpenSendConnections
        let isActive = recordingManager.recordingState.isActive

        let disableStart = isActive || isSending
        let disableStop = !isActive || (!isActive && isSending)

        VStack {
            Button {
                startRecording()
            } label: {
                Label("Start", systemImage: "play.fill")
                    .labelStyle(WatchMenuLabelStyle())
            }
            .disabled(disableStart)
            .tint(.green)

            Button {
                stopRecording()
            } label: {
                Label("End", systemImage: "xmark")
                    .labelStyle(WatchMenuLabelStyle())
            }
            .tint(.red)
            .disabled(disableStop)

            Spacer()

            if isSending {
                SpinnerView(text: "Sending Data")
            }
        }
        .disabled(loading)
        .alert(errorMessage, isPresented: $showAlert) {
            Button("Cancel", role: .destructive) {
                reset()
                stopRecording()
            }
            Button("Dismiss", role: .cancel) {
                startRecordingWithoutPhone()
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
    private func stopRecording() {
        Task {
            self.loading = true
            await recordingManager.workoutManager.stop()
            self.loading = false
        }
    }
    private func startRecording() {
        Task {
            self.loading = true
            do {
                try await recordingManager.start()
            } catch {
                Logger.shared.error("Error starting workout: \(error)")
                self.error = error
                self.showAlert = true
            }
            self.loading = false
        }
    }
    private func startRecordingWithoutPhone() {
        Task {
            self.loading = true
            do {
                try await recordingManager.startWorkout()
            } catch {
                Logger.shared.error("Error starting workout: \(error)")
                self.error = error
                self.showAlert = true
            }
            self.loading = false
        }
    }
}
