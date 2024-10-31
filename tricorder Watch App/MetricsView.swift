/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout metrics.
*/

import HealthKit
import SwiftUI

struct MetricsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var nearbyInteractionManager = NearbyInteractionManager()

    var body: some View {
        TimelineView(
            MetricsTimelineSchedule(
                from: workoutManager.session?.startDate ?? Date(),
                isPaused: workoutManager.sessionState == .paused)
        ) { context in
            VStack(alignment: .leading) {
                ElapsedTimeView(
                    elapsedTime: elapsedTime(with: context.date),
                    showSubseconds: context.cadence == .live
                )
                .foregroundStyle(.yellow)
                Text(
                    workoutManager.heartRate.formatted(
                        .number.precision(.fractionLength(0))) + " bpm")
                
                if let distance = nearbyInteractionManager.distance?.converted(to: .centimeters) {
                    Text(distance.value.formatted(.number.precision(.fractionLength(2))))
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
        return workoutManager.builder?.elapsedTime(at: contextDate) ?? 0
    }
}
