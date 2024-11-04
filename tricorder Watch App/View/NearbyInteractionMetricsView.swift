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
