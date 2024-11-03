//
//  MetricsView.swift
//  tricorder
//
//  Created by Julian Visser on 03.11.2024.
//

import SwiftUI

struct MetricsView: View {
    @EnvironmentObject var recordingManager: RecordingManager

    var body: some View {
        Group {
            LabeledContent(
                "Heart Rate",
                value: recordingManager.heartRate,
                format: .number.precision(.fractionLength(0))
            )
        }
        .font(
            .system(.title2, design: .rounded).monospacedDigit()
                .lowercaseSmallCaps()
        )
    }
}
