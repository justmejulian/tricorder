/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout metrics.
*/

import HealthKit
import SwiftUI

struct MetricsView: View {
    @ObservedObject
    var statisticsManager: StatisticsManager

    @ObservedObject
    var nearbyInteractionManager: NearbyInteractionManager

    var body: some View {
        HStack {
            Text(formatHeartRate(statisticsManager.mostRecentHeartRate))
            Spacer()
            Text(formatDistance(nearbyInteractionManager.distance))
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
