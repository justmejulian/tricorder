//
//  LineChart.swift
//  tricorder
//
//  Created by Julian Visser on 04.11.2024.
//

import Charts
import SwiftUI

struct LineChart: View {

    let dataPoints: [DataPoint]

    var body: some View {
        let curColor = Color.blue
        let curGradient = LinearGradient(
            gradient: Gradient(
                colors: [
                    curColor.opacity(0.5),
                    curColor.opacity(0.2),
                    curColor.opacity(0.05),
                ]
            ),
            startPoint: .top,
            endPoint: .bottom
        )

        Chart(dataPoints, id: \.timestamp) {
            LineMark(
                x: .value("Time", $0.timestamp),
                y: .value("Value", $0.value)
            )
            .lineStyle(.init(lineWidth: 2))
            .interpolationMethod(.cardinal)

            AreaMark(
                x: .value("Time", $0.timestamp),
                y: .value("Value", $0.value)
            )
            .interpolationMethod(.cardinal)
            .foregroundStyle(curGradient)
        }
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
    }
}

extension LineChart {
    struct DataPoint {
        let timestamp: Date
        let value: Double
    }
}
