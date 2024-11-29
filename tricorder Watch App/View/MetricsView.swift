/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout metrics.
*/

import HealthKit
import SwiftUI

struct MetricsView: View {
    @ObservedObject
    var heartRateManager: ObservableValueManager<StatisticValue>

    @ObservedObject
    var distanceManager: ObservableValueManager<DistanceValue>

    var body: some View {
        HStack {
            Text(formatHeartRate(heartRateManager.mostRecent?.value))
            Spacer()
            Text(formatDistance(distanceManager.mostRecent?.avg))
        }
        .font(
            .system(.title2, design: .rounded)
                .monospacedDigit()
                .lowercaseSmallCaps()
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .ignoresSafeArea(edges: .bottom)
    }
}
