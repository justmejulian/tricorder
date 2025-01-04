//
//  RecordingListView.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import OSLog
import SwiftData
import SwiftUI

struct RecordingListView: View {
    @EnvironmentObject var recordingManager: RecordingManager
    @Environment(\.dismiss) private var dismiss

    @State
    var recordings: [RecordingDatabaseModel.Struct] = []
    @State
    var loading = false

    var body: some View {
        List(recordings, id: \.startTimestamp) { recording in
            NavigationLink {
                RecordingDetailView(recordingStartTime: recording.startTimestamp)
            } label: {
                VStack {
                    Text(recording.name)
                    Text(recording.startTimestamp.ISO8601Format()).font(.caption)
                }
            }
        }
        .onAppear {
            Task {
                loading = true
                recordings = await getRecordings()
                loading = false
            }
        }
        .navigationBarItems(
            trailing:
                ClearAllConfirmationButton(
                    callback: {
                        dismiss()
                    }
                ) {
                    Image(systemName: "xmark.bin")
                }
        )
        .overlay {
            if loading {
                SpinnerView(text: "Loading")
            }
            if !loading && recordings.isEmpty {
                ContentUnavailableView(
                    "No recordings yet",
                    systemImage: "recordingtape"
                )
            }
        }
    }
}

extension RecordingListView {
    func getRecordings() async -> [RecordingDatabaseModel.Struct] {
        do {
            let modelContainer = recordingManager.modelContainer
            let handler = RecordingBackgroundDataHandler(modelContainer: modelContainer)
            return try await handler.getRecordings()
        } catch {
            Logger.shared.error("Failed to fecht recordings: \(error)")
            return []
        }
    }
}
