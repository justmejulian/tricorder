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
    var values: [String: Int] = [:]
    @State
    var loading = false

    // todo replace with backgorund fetch
    var body: some View {
        VStack {
            if loading {
                SpinnerView(text: "Loading")
            } else {
                Text(recordingStartTime.ISO8601Format()).font(.headline)
                // todo make into something better looking
                List(values.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    Text("# \(key): \(value)")
                }

                FileExportButton(recordingStartDate: recordingStartTime)
            }
        }
        .onAppear {
            setLoading(true)
            Task.detached {
                let values = await getSensorValueCounts(recordingStart: recordingStartTime)
                await setValues(values)
                await setLoading(false)
            }
        }
        .overlay {
            if !loading && values.isEmpty {
                ContentUnavailableView(
                    "No Sensor Data",
                    systemImage: "sensor"
                )
            }
        }

    }
}

extension RecordingDetailView {
    func setLoading(_ loading: Bool) {
        self.loading = loading
    }

    func setValues(_ values: [String: Int]) {
        self.values = values
    }

    nonisolated func getSensorValueCounts(recordingStart: Date) async -> [String: Int] {
        do {
            let modelContainer = await recordingManager.modelContainer
            let handler = SensorBackgroundDataHandler(modelContainer: modelContainer)
            return try await handler.getSensorValueCounts(
                recordingStart: recordingStart
            )
        } catch {
            Logger.shared.error("Failed to fecht bytes for: \(recordingStart) \(error)")
            return [:]
        }
    }
}
