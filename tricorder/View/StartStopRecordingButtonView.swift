//
//  StartStopRecordingButtonView.swift
//  tricorder
//
//  Created by Julian Visser on 03.11.2024.
//

import SwiftUI

// MARK: - StartStopRecordingButtonView View
//
struct StartStopRecordingButtonView: View {
    // todo do I need this or can it be passed down?
    @EnvironmentObject var recordingManager: RecordingManager

    var body: some View {
        var isActive = recordingManager.recordingState.isActive

        StartStopRecordingButton(
            title: isActive ? "Stop Recording" : "Start Recording",
            action: isActive ? stopRecording : startRecording
        )
    }
}

// MARK: - StartStopRecordingButtonView SubViews
//
extension StartStopRecordingButtonView {
    struct StartStopRecordingButton: View {
        var title: String
        var action: @MainActor () -> Void

        var body: some View {
            Button {
                action()
            } label: {
                ButtonLabel(
                    title: title,
                    systemImage: "figure.outdoor.cycle"
                )
            }
            .padding()
            .background(Color(red: 0, green: 0, blue: 0.5))
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
    }
}

// MARK: - StartStopRecordingButtonView functions
//
extension StartStopRecordingButtonView {
    func startRecording() {
        // todo error handling
        Task {
            await recordingManager.startRecording()
        }
    }

    func stopRecording() {
        Task {
            await recordingManager.stopRecording()
        }
    }
}
