/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout summary.
*/

import HealthKit
import SwiftUI

struct SummaryView: View {
    @Binding var workout: HKWorkout?

    var body: some View {
        if let workout = workout {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                GridItemView(title: "Total Time", value: workout.totalTime)
                    .foregroundStyle(.yellow)
                
                GridItemView(title: "Average Heartrate", value: workout.averageHeartRate)
                    .foregroundStyle(.black)
            }
        }
    }
}

private struct GridItemView: View {
    var title: String
    var value: String

    var body: some View {
        VStack {
            Text(title)
                .foregroundStyle(.foreground)
            Text(value)
                .font(.system(.title2, design: .rounded).lowercaseSmallCaps())
        }
    }
}
