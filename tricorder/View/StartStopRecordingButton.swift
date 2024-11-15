//
//  StartStopRecordingButtonView.swift
//  tricorder
//
//  Created by Julian Visser on 03.11.2024.
//

import SwiftUI
import os

struct StartStopRecordingButton: View {
    // todo do I need this or can it be passed down?
    @EnvironmentObject var recordingManager: RecordingManager

    @ObservedObject
    var connectivityMetaInfoManager: ConnectivityMetaInfoManager

    @State private var error: Error?
    @State private var showAlert: Bool = false
    @State private var loading: Bool = false

    var body: some View {
        let isActive = recordingManager.recordingState.isActive
        let isReceivingData =
            !isActive && connectivityMetaInfoManager.isLastDidReceiveDataDateTooRecent

        var title: String {
            if isReceivingData {
                return "Receiving Data"
            }
            if isActive {
                return "Stop Recording"
            }
            return "Start Recording"
        }

        var errorMessage: String {
            if let localizedDescription = error?.localizedDescription {
                return localizedDescription
            }

            return "Something went wrong starting the workout."
        }

        StartStopRecordingButton(
            title: title,
            tint: isActive ? .red : .blue,
            action: isActive ? stopRecording : startRecording
        )
        .disabled(loading || isReceivingData)
        .alert(errorMessage, isPresented: $showAlert) {
            Button("Dismiss", role: .cancel) {
                reset()
                stopRecording()
            }
        }
    }
}

// MARK: - StartStopRecordingButtonView SubViews
//
extension StartStopRecordingButton {
    struct StartStopRecordingButton: View {
        var title: String
        var tint: Color
        var action: @MainActor () -> Void

        var body: some View {

            Button {
                action()
            } label: {
                Text(title)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(tint)
        }
    }
}

// MARK: - StartStopRecordingButtonView functions
//
extension StartStopRecordingButton {
    private func reset() {
        self.error = nil
        self.showAlert = false
    }

    func startRecording() {
        // todo error handling
        Task {
            self.loading = true
            do {
                try await recordingManager.startRecording()
            } catch {
                Logger.shared.error("Error starting recording: \(error)")
                self.showAlert = true
                self.error = error
            }
            self.loading = false
        }
    }

    func stopRecording() {
        Task {
            self.loading = true
            await recordingManager.stopRecording()
            self.loading = false
        }
    }
}
