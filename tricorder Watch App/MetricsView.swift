/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout metrics.
*/

import HealthKit
import SwiftUI

struct MetricsView: View {
    @EnvironmentObject var recordingManager: RecordingManager

    var body: some View {
        TimelineView(
            MetricsTimelineSchedule(
                from: recordingManager.workoutManager.session?.startDate
                    ?? Date(),
                isPaused: recordingManager.workoutManager.sessionState
                    == .paused)
        ) { context in
            VStack(alignment: .leading) {
                ElapsedTimeView(
                    elapsedTime: elapsedTime(with: context.date),
                    showSubseconds: context.cadence == .live
                )
                .foregroundStyle(.yellow)

                Text(
                    recordingManager.workoutManager.heartRate.formatted(
                        .number.precision(.fractionLength(0))) + " bpm")

                if let distance = recordingManager.nearbyInteractionManager
                    .distance?.converted(to: .meters)
                {
                    Text(localFormatter.string(from: distance)).font(.title)
                } else {
                    Text("-")
                }
            }
            .font(
                .system(.title, design: .rounded).monospacedDigit()
                    .lowercaseSmallCaps()
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .ignoresSafeArea(edges: .bottom)
            .scenePadding()
            .padding([.top], 30)
        }
    }

    func elapsedTime(with contextDate: Date) -> TimeInterval {
        return recordingManager.workoutManager.builder?.elapsedTime(
            at: contextDate) ?? 0
    }

    var localFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.alwaysShowsDecimalSeparator = true
        formatter.numberFormatter.roundingMode = .ceiling
        formatter.numberFormatter.maximumFractionDigits = 1
        formatter.numberFormatter.minimumFractionDigits = 1
        return formatter
    }()
}
