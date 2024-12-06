//
//  PersistedView.swift
//
//  Created by Julian Visser on 06.12.2024.
//

import OSLog
import SwiftUI

struct PersistedView: View {
    @EnvironmentObject var recordingManager: RecordingManager

    @State
    var count = 0
    @State
    var loading = false

    var body: some View {
        VStack {
            if count > 0 {
                Text("Unsynced Data Count")
                Text(String(count))
            } else {
                ContentUnavailableView(
                    "No unsynced data",
                    systemImage: "recordingtape"
                )
            }
            HStack {
                Button {
                    Task {
                        loading = true
                        try await sendData()
                        loading = false
                    }
                } label: {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")

                }
                ClearAllConfirmationButton {
                    Image(systemName: "xmark.bin")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if loading {
                SpinnerView(text: "Loading")
            }
        }
        .onAppear {
            Task {
                loading = true
                count = await getDataCount()
                loading = false
            }
        }
    }
}

extension PersistedView {
    func getDataCount() async -> Int {
        do {
            let modelContainer = recordingManager.modelContainer
            let handler = PersistedDataHandler(modelContainer: modelContainer)
            return try await handler.fetchAllPersistentIdentifiers().count
        } catch {
            Logger.shared.error("Failed to fecht data: \(error)")
            return 0
        }
    }

    func sendData() async throws {
        try await recordingManager.sendUnsyced()
    }
}
