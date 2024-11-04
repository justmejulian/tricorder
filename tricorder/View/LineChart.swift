//
//  LineChart.swift
//  tricorder
//
//  Created by Julian Visser on 04.11.2024.
//

import Charts
import SwiftUI

private var data: [LineData] = [
    LineData(city: "Seattle", month: 1, hoursOfSunshine: 74),
    LineData(city: "Cupertino", month: 1, hoursOfSunshine: 156),
    LineData(city: "Seattle", month: 2, hoursOfSunshine: 99),
    LineData(city: "Cupertino", month: 2, hoursOfSunshine: 174),
    LineData(city: "Seattle", month: 3, hoursOfSunshine: 104),
    LineData(city: "Cupertino", month: 3, hoursOfSunshine: 209),
    LineData(city: "Seattle", month: 4, hoursOfSunshine: 135),
    LineData(city: "Cupertino", month: 4, hoursOfSunshine: 230),
    LineData(city: "Seattle", month: 5, hoursOfSunshine: 174),
    LineData(city: "Cupertino", month: 5, hoursOfSunshine: 276),
    LineData(city: "Seattle", month: 6, hoursOfSunshine: 203),
    LineData(city: "Cupertino", month: 6, hoursOfSunshine: 314),
    LineData(city: "Seattle", month: 7, hoursOfSunshine: 231),
    LineData(city: "Cupertino", month: 7, hoursOfSunshine: 333),
    LineData(city: "Seattle", month: 8, hoursOfSunshine: 209),
    LineData(city: "Cupertino", month: 8, hoursOfSunshine: 317),
    LineData(city: "Seattle", month: 9, hoursOfSunshine: 164),
    LineData(city: "Cupertino", month: 9, hoursOfSunshine: 261),
    LineData(city: "Seattle", month: 10, hoursOfSunshine: 123),
    LineData(city: "Cupertino", month: 10, hoursOfSunshine: 209),
    LineData(city: "Seattle", month: 11, hoursOfSunshine: 95),
    LineData(city: "Cupertino", month: 11, hoursOfSunshine: 173),
    LineData(city: "Seattle", month: 12, hoursOfSunshine: 62),
    LineData(city: "Cupertino", month: 12, hoursOfSunshine: 131),
]

struct LineChart: View {
    var body: some View {
        Chart(data) {
            LineMark(
                x: .value("Month", $0.date),
                y: .value("Hours of Sunshine", $0.hoursOfSunshine)
            ).foregroundStyle(by: .value("City", $0.city))
        }
    }
}

struct LineData: Identifiable {
    var city: String
    var date: Date
    var hoursOfSunshine: Double
    let id = UUID()

    init(city: String, month: Int, hoursOfSunshine: Double) {
        let calendar = Calendar.autoupdatingCurrent
        self.city = city
        self.date = calendar.date(from: DateComponents(year: 2020, month: month))!
        self.hoursOfSunshine = hoursOfSunshine
    }
}
