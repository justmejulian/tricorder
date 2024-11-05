import HealthKit
import SwiftUI

struct NearbyInteractionMetricsView: View {
    @EnvironmentObject var recordingManager: RecordingManager

    var body: some View {
        let distance =
            recordingManager.nearbyInteractionManager.distance?.converted(to: .meters)
            ?? Measurement(value: 0, unit: .meters)

        Text(localFormatter.string(from: distance))
    }


}
