//
//  MetricsView.swift
//  tricorder
//
//  Created by Julian Visser on 03.11.2024.
//

import SwiftUI

struct MetricsView: View {
    @EnvironmentObject var recordingManager: RecordingManager

    @ObservedObject
    var classifierManager: ClassifierManager

    var body: some View {
        VStack {
            HStack {
                MetricsBox(
                    title: "Heart Rate",
                    value: formatHeartRate(classifierManager.heartRateManager.mostRecent?.value)
                )
                MetricsBox(
                    title: "# Heart Rate",
                    value: String(classifierManager.heartRateManager.count)
                )
            }
            HStack {
                MetricsBox(
                    title: "Distance",
                    value: formatDistance(classifierManager.distanceManager.mostRecent?.avg)
                )
                MetricsBox(
                    title: "# Distance",
                    value: String(classifierManager.distanceManager.count)
                )
            }
            HStack {
                MetricsBox(
                    title: "Top Acceleration",
                    value: "\(classifierManager.topAcceleration) m/s^2"
                )
                MetricsBox(
                    title: "# Motion Data",
                    value: String(classifierManager.motionManager.count)
                )
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
                        .system(.title3, design: .rounded).monospaced()
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
