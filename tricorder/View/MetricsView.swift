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
        VStack {
            HStack {
                MetricsBox(title: "Heart Rate", value: "\(recordingManager.heartRate) BPM")
                MetricsBox(title: "Avg Heart Rate", value: "\(recordingManager.heartRate) BPM")
            }
            HStack {
                MetricsBox(title: "Distance", value: "\(recordingManager.nearbyInteractionManager.distance ?? 0) m")
                MetricsBox(title: "Heart Rate", value: "\(recordingManager.heartRate) BPM")
            }
            HStack {
                MetricsBox(title: "Heart Rate", value: "\(recordingManager.heartRate) BPM")
                MetricsBox(title: "Heart Rate", value: "\(recordingManager.heartRate) BPM")
            }
        }
    }
}

extension MetricsView {
    struct MetricsBox: View {
        let title: String
        let value: String
        var body: some View {
            VStack {
                Text(title)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(String(value))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(
                        .system(.title, design: .rounded).monospaced()
                            .lowercaseSmallCaps()
                    )
            }
            .padding()
            //            .background(.gray.opacity(0.5))
            .background(.gray.opacity(0.5))
            .cornerRadius(8)
        }
    }
}
