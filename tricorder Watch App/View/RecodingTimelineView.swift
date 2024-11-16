//
//  RecodingTimelineView.swift
//  tricorder
//
//  Created by Julian Visser on 03.11.2024.
//

import SwiftUI
import os

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
                statisticsManager: recordingManager.statisticsManager,
                distanceManager: recordingManager.distanceManager
            )
        }
        .scenePadding()
    }
}
