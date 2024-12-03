//
//  RecodingTimelineView.swift
//  tricorder
//
//  Created by Julian Visser on 03.11.2024.
//

import OSLog
import SwiftUI

struct RecodingTimelineView: View {
    @EnvironmentObject var recordingManager: RecordingManager

    var body: some View {
        let schedule = MetricsTimelineSchedule(
            from: Date(),
            isPaused: recordingManager.recordingState
                == .ended
        )
        TimelineView(schedule) { context in
            RecordingElapsedTimeView(context: context)
            DotsView(
                monitoringManager: recordingManager.monitoringManager
            )
            MetricsView(
                heartRateManager: recordingManager.heartRateManager,
                distanceManager: recordingManager.distanceManager
            )
        }
        .scenePadding()
    }
}
