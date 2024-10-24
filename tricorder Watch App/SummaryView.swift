/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout summary information.
*/

import Foundation
import HealthKit
import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        if let workout = workoutManager.workout {
            ScrollView {
                summaryListView(workout: workout)
                    .scenePadding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ProgressView("Saving Workout")
                .navigationBarHidden(true)
        }
    }
    
    @ViewBuilder
    private func summaryListView(workout: HKWorkout) -> some View {
        VStack(alignment: .leading) {
            SummaryMetricView(title: "Total Time", value: workout.totalTime)
                .foregroundStyle(.yellow)
            
            SummaryMetricView(title: "Avg. Heart Rate", value: workout.averageHeartRate)
                .foregroundStyle(.red)
        }
    }
}

struct SummaryMetricView: View {
    var title: String
    var value: String

    var body: some View {
        Text(title)
            .foregroundStyle(.foreground)
        Text(value)
            .font(.system(.title2, design: .rounded).lowercaseSmallCaps())
        Divider()
    }
}
