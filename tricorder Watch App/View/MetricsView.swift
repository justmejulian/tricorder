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
        VStack(alignment: .leading) {
            HeartRateMetricsView()
            NearbyInteractionMetricsView()
        }
        .font(
            .system(.title2, design: .rounded)
                .monospacedDigit()
                .lowercaseSmallCaps()
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .ignoresSafeArea(edges: .bottom)
        .padding([.top], 8)
    }
}
