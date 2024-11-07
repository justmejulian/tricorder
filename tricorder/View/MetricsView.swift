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
    var statisticsManager: StatisticsManager

    @ObservedObject
    var nearbyInteractionManager: NearbyInteractionManager

    @ObservedObject
    var motionManager: MotionManager

    var body: some View {
        VStack {
            HStack {
                MetricsBox(
                    title: "Heart Rate",
                    value: formatHeartRate(statisticsManager.mostRecentHeartRate)
                )
                // todo avg
                MetricsBox(
                    title: "Avg Heart Rate",
                    value: formatHeartRate(statisticsManager.avgHeartRate)
                )
            }
            HStack {
                MetricsBox(
                    title: "Distance",
                    value: formatDistance(nearbyInteractionManager.distance)
                )
                MetricsBox(
                    title: "Top Speed",
                    value: "42 km/h"
                )
            }
            HStack {
                MetricsBox(
                    title: "# Motion Data",
                    value: String(motionManager.motionValues.count)
                )
                MetricsBox(
                    title: "# Statistics",
                    value: String(statisticsManager.statistics.count)
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
