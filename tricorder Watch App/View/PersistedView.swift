//
//  PersistedView.swift
//
//  Created by Julian Visser on 06.12.2024.
//

import OSLog
import SwiftUI

struct PersistedView: View {
    let navigateBack: () -> Void

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
                ClearAllConfirmationButton(
                    callback: navigateBack
                ) {
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
        let handler = PersistedDataHandler(modelContainer: recordingManager.modelContainer)
        let ids = try await handler.fetchAllPersistentIdentifiers()

        var failedCount = 0

        // break up, so that can sync more at once
        let chundedIds = ids.chunked(into: 10)

        // todo improve to maybe batch and compress
        for ids in chundedIds {
            if failedCount > 5 {
                break
            }
            let dataArray = try await handler.getData(for: ids)
            let tasks = dataArray.map { data in
                Task {
                    try await recordingManager.sendSensorUpdate([data])
                }
            }

            do {
                for task in tasks {
                    try await task.value
                }

                // If none fail then remove all
                count -= tasks.count
                try await handler.removeData(identifiers: ids)
            } catch {
                Logger.shared.error("Failed during sync: \(error)")
                failedCount += 1
            }

        }
    }
}
