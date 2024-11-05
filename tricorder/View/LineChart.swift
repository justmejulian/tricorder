//
//  LineChart.swift
//  tricorder
//
//  Created by Julian Visser on 04.11.2024.
//

import Charts
import SwiftUI

private let data: [LineData] = [
    LineData(time: 0, speed: 0),
    LineData(time: 1, speed: 0),
    LineData(time: 1.5, speed: 100),
    LineData(time: 2, speed: 10),
    LineData(time: 4, speed: 100),
    LineData(time: 4.5, speed: 0),
    LineData(time: 5, speed: 20),
    LineData(time: 6, speed: 10),
    LineData(time: 6.5, speed: 180),
    LineData(time: 7, speed: 100),
    LineData(time: 8, speed: 0),
    LineData(time: 9, speed: 10),
    LineData(time: 10, speed: 0),
]

struct LineChart: View {
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

        Chart(data) {
            LineMark(
                x: .value("Time", $0.time),
                y: .value("Speed", $0.speed)
            )
            .lineStyle(.init(lineWidth: 2))
            .interpolationMethod(.cardinal)

            AreaMark(
                x: .value("Time", $0.time),
                y: .value("Speed", $0.speed)
            )
            .interpolationMethod(.cardinal)
            .foregroundStyle(curGradient)
        }
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
    }
}

struct LineData: Identifiable {
    var id: UUID

    var time: Double
    var speed: Double

    init(time: Double, speed: Double) {
        self.id = UUID()
        self.time = time
        self.speed = speed
    }
}
