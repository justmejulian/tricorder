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

    @ObservedObject var connectivityMetaInfoManager: ConnectivityMetaInfoManager

    @ObservedObject
    var alertManager: AlertManager

    @Binding var showAlert: Bool
    @State private var loading: Bool = false

    var body: some View {
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
        .onAppear {
            Task {
                if let missingPermission = await recordingManager.getFirstMissingPermission() {
                    alertManager.configure(
                        title: "Error",
                        message:
                            "User missing \(missingPermission) Permission. Please enable it in the settings.",
                        primaryButton: .cancel(Text("Exit")) {
                            exit(0)
                        }
                    )
                    return
                }
            }
        }
        .disabled(loading)
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
                self.alertManager.configure(
                    title: "Error",
                    message: error.localizedDescription,
                    primaryButton: .destructive(Text("Cancel")) {
                        cancelRecording()
                    },
                    secondaryButton: .cancel(Text("Dismiss")) {
                        startRecordingWithoutPhone()
                    }
                )
            }
            self.loading = false
        }
    }

    private func cancelRecording() {
        stopRecording()
        reset()
    }

    private func startRecordingWithoutPhone() {
        Task {
            self.loading = true
            do {
                try await recordingManager.startWorkout()
            } catch {
                Logger.shared.error("Error starting workout: \(error)")
                self.alertManager.configure(
                    title: "Error",
                    message: error.localizedDescription,
                    primaryButton: .destructive(Text("Cancel")) {
                        cancelRecording()
                    }
                )
            }
            self.loading = false
        }
    }
}
