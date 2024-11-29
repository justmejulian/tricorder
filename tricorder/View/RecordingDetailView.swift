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
    var motionDataCount = 0

    // todo replace with backgorund fetch
    var body: some View {
        VStack {
            Text(recordingStartTime.ISO8601Format())
            Text("# Motion Data: \(motionDataCount)")
        }
        .task {
            self.motionDataCount = await getMotionDataCount(recordingStart: recordingStartTime)
        }
    }
}

extension RecordingDetailView {
    nonisolated func getMotionDataCount(recordingStart: Date) async -> Int {
        do {
            let modelContainer = await recordingManager.modelContainer
            let handler = SensorBackgroundDataHandler(modelContainer: modelContainer)
            let ids = try await handler.getMotionSensorPersistentIdentifiers(
                recordingStart: recordingStart
            )
            return ids.count
        } catch {
            Logger.shared.error("Failed to fecht motion data count: \(error.localizedDescription)")
            return 0
        }
    }
}
