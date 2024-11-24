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
    var heartRateManager: ObservableValueManager<HeartRateValue>

    @ObservedObject
    var distanceManager: ObservableValueManager<DistanceValue>

    @ObservedObject
    var motionManager: MotionManager

    var body: some View {
        VStack {
            HStack {
                MetricsBox(
                    title: "Heart Rate",
                    value: formatHeartRate(heartRateManager.mostRecent?.value)
                )
                MetricsBox(
                    title: "# Heart Rate",
                    value: String(heartRateManager.count)
                )
            }
            HStack {
                MetricsBox(
                    title: "Distance",
                    value: formatDistance(distanceManager.mostRecent?.avg)
                )
                MetricsBox(
                    title: "# Distance",
                    value: String(distanceManager.count)
                )
            }
            HStack {
                MetricsBox(
                    title: "Top Speed",
                    value: "42 km/h"
                )
                MetricsBox(
                    title: "# Motion Data",
                    value: String(motionManager.count)
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
