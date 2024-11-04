//
//  StartStopRecordingButtonView.swift
//  tricorder
//
//  Created by Julian Visser on 03.11.2024.
//

import SwiftUI

struct StartStopRecordingButton: View {
    // todo do I need this or can it be passed down?
    @EnvironmentObject var recordingManager: RecordingManager

    var body: some View {
        let isActive = recordingManager.recordingState.isActive

        StartStopRecordingButton(
            title: isActive ? "Stop Recording" : "Start Recording",
            tint: isActive ? .red : .blue,
            action: isActive ? stopRecording : startRecording
        )
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
