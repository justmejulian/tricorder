//
//  MetricsView.swift
//  tricorder
//
//  Created by Julian Visser on 03.11.2024.
//

import SwiftUI

struct MetricsView: View {
    @ObservedObject
    var statisticsManager: StatisticsManager

    @ObservedObject
    var nearbyInteractionManager: NearbyInteractionManager

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
                    value: formatHeartRate(statisticsManager.mostRecentHeartRate)
                )
            }
            HStack {
                MetricsBox(
                    title: "Distance",
                    value: formatDistance(nearbyInteractionManager.distance)
                )
                MetricsBox(
                    title: "Heart Rate",
                    value: formatHeartRate(statisticsManager.mostRecentHeartRate)
                )
            }
            HStack {
                MetricsBox(
                    title: "Heart Rate",
                    value: formatHeartRate(statisticsManager.mostRecentHeartRate)
                )
                MetricsBox(
                    title: "Heart Rate",
                    value: formatHeartRate(statisticsManager.mostRecentHeartRate)
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
