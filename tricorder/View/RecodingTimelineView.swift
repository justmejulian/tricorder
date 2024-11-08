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
            // todo move to get function
            from: recordingManager.workoutManager.session?.startDate
                ?? Date(),
            isPaused: recordingManager.recordingState
                == .ended
        )
        TimelineView(schedule) { context in
            VStack {
                RecordingElapsedTimeView(context: context)
                Spacer()
                Spacer()
                LineChart()
                Spacer()
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.gray, lineWidth: 1)
            )

            Spacer()
            Spacer()

            MetricsView(
                statisticsManager: recordingManager.statisticsManager,
                distanceManager: recordingManager.distanceManager,
                motionManager: recordingManager.motionManager
            )
        }
    }
}
