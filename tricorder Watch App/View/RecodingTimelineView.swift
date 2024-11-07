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
            from: recordingManager.workoutManager.session?.startDate
                ?? Date(),
            isPaused: recordingManager.recordingState
                == .ended
        )
        TimelineView(schedule) { context in
            RecordingElapsedTimeView(context: context)
            DotsView(
                motionManager: recordingManager.motionManager
            )
            MetricsView(
                statisticsManager: recordingManager.statisticsManager,
                nearbyInteractionManager: recordingManager.nearbyInteractionManager
            )
        }
        .scenePadding()
    }
}
