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
        let fromDate =
            recordingManager.workoutManager.session?.startDate ?? Date()
        let schedule = MetricsTimelineSchedule(
            from: fromDate,
            isPaused: recordingManager.recordingState == .ended
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

            MetricsView()
        }
    }
}
