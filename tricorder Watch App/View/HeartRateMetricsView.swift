import HealthKit
import SwiftUI

struct HeartRateMetricsView: View {
    @EnvironmentObject var recordingManager: RecordingManager

    var body: some View {
        Text(
            recordingManager.heartRate.formatted(
                .number.precision(.fractionLength(0))
            ) + " bpm"
        )
    }
}
