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

    @State private var usePhone: Bool = true

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

        VStack {
            Toggle(isOn: $usePhone) {
                Text("Use Phone")
            }
            .padding(.horizontal, 20)
            .disabled(isActive || isSending)

            Spacer()

            if isSending {
                SpinnerView(text: "Sending Data")
            }

            Spacer()

            Button {
                if isActive {
                    stopWorkout()
                } else {
                    startWorkout()
                }
            } label: {
                if isActive {
                    Label("End", systemImage: "xmark")
                        .labelStyle(WatchMenuLabelStyle())
                } else {
                    Label("Start", systemImage: "play.fill")
                        .labelStyle(WatchMenuLabelStyle())
                }
            }
            .tint(isActive ? .red : .green)
            .disabled(!isActive && isSending)
        }
        .disabled(loading)
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
        Task {
            self.loading = true
            await recordingManager.workoutManager.stop()
            self.loading = false
        }
    }
    private func startWorkout() {
        Task {
            self.loading = true
            do {
                try await recordingManager.startRecording(withPhone: usePhone)
            } catch {
                Logger.shared.error("Error starting workout: \(error)")
                self.error = error
                self.showAlert = true
            }
            self.loading = false
        }
    }
}
