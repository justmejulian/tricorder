//
//  RecordingDetailView.swift
//
//  Created by Julian Visser on 28.11.2024.
//

import Foundation
import SwiftData
import SwiftUI
import os

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
                    Text("\(key): \(value) bytes")
                }
            } else {
                Text("No Sensor Data")
            }
        }
        .task {
            self.values = await getSensorValueBytes(recordingStart: recordingStartTime)
        }
    }
}

extension RecordingDetailView {
    nonisolated func getSensorValueBytes(recordingStart: Date) async -> [String: Int]? {
        do {
            let modelContainer = await recordingManager.modelContainer
            let handler = SensorBackgroundDataHandler(modelContainer: modelContainer)
            return try await handler.getSensorValueBytes(
                recordingStart: recordingStart
            )
        } catch {
            Logger.shared.error("Failed to fecht motion data count: \(error.localizedDescription)")
            return nil
        }
    }
}
