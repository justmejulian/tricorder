/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that controls the mirroring workout session and presents the metrics.
*/

import HealthKit
import SwiftUI
import os

struct MirroringWorkoutView: View {
    @EnvironmentObject var recordingManager: RecordingManager

    var body: some View {
        let fromDate =
            recordingManager.workoutManager.session?.startDate ?? Date()
        let schedule = MetricsTimelineSchedule(
            from: fromDate,
            isPaused: recordingManager.recordingState == .paused
        )
        TimelineView(schedule) { context in
            List {
                Section {
                    metricsView()
                } header: {
                    headerView(context: context)
                } footer: {
                    footerView()
                }
            }
        }
    }
}

extension MirroringWorkoutView {
    @ViewBuilder
    private func headerView(context: TimelineViewDefaultContext) -> some View {
        VStack {
            Spacer(minLength: 30)
            LabeledContent {
                ElapsedTimeView(
                    elapsedTime: workoutTimeInterval(context.date),
                    showSubseconds: context.cadence == .live
                )
                .font(
                    .system(.title, design: .rounded).monospacedDigit()
                        .lowercaseSmallCaps()
                )
            } label: {
                Text("Elapsed")
            }
            .foregroundColor(.yellow)
            .font(
                .system(.title, design: .rounded).monospacedDigit()
                    .lowercaseSmallCaps()
            )
            Spacer(minLength: 15)
        }
    }

    private func workoutTimeInterval(_ contextDate: Date) -> TimeInterval {
        var timeInterval = recordingManager.elapsedTimeInterval
        if recordingManager.recordingState == .running {
            if let referenceContextDate = recordingManager.workoutManager
                .contextDate
            {
                timeInterval +=
                    (contextDate.timeIntervalSinceReferenceDate
                        - referenceContextDate.timeIntervalSinceReferenceDate)
            } else {
                recordingManager.workoutManager.contextDate = contextDate
            }
        } else {
            var date = contextDate
            date.addTimeInterval(
                recordingManager.elapsedTimeInterval
            )
            timeInterval =
                date.timeIntervalSinceReferenceDate
                - contextDate.timeIntervalSinceReferenceDate
            recordingManager.workoutManager.contextDate = nil
        }
        return timeInterval
    }

    @ViewBuilder
    private func footerView() -> some View {
        VStack {
            Spacer(minLength: 40)
            HStack {
                Button {
                    Task {
                        await recordingManager.stopRecording()
                    }
                } label: {
                    ButtonLabel(title: "End", systemImage: "xmark")
                }
                .tint(.green)
                .disabled(
                    !recordingManager.recordingState.isActive
                )

            }
            .buttonStyle(.bordered)
        }
    }
}
