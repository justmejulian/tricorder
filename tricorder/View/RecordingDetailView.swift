//
//  RecordingDetailView.swift
//
//  Created by Julian Visser on 28.11.2024.
//

import Foundation
import OSLog
import SwiftData
import SwiftUI

struct RecordingDetailView: View {
    @EnvironmentObject var recordingManager: RecordingManager

    let recordingStartTime: Date

    @State
    var values: [String: Int]?

    // todo replace with backgorund fetch
    var body: some View {
        VStack {
            Text(recordingStartTime.ISO8601Format()).font(.headline)
            // todo make into something better looking
            if let values {
                List(values.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    Text("# \(key): \(value)")
                }
            } else {
                Text("No Sensor Data")
            }

            FileExportButton(recordingStartDate: recordingStartTime)
        }
        .task {
            self.values = await getSensorValueCounts(recordingStart: recordingStartTime)
        }
    }
}

extension RecordingDetailView {
    nonisolated func getSensorValueCounts(recordingStart: Date) async -> [String: Int]? {
        do {
            let modelContainer = await recordingManager.modelContainer
            let handler = SensorBackgroundDataHandler(modelContainer: modelContainer)
            return try await handler.getSensorValueCounts(
                recordingStart: recordingStart
            )
        } catch {
            Logger.shared.error("Failed to fecht bytes for: \(recordingStart) \(error)")
            return nil
        }
    }
}
