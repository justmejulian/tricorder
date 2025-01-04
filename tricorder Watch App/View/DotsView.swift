//
//  DotsView.swift
//  tricorder
//
//  Created by Julian Visser on 05.11.2024.
//

import SwiftUI

struct DotsView: View {
    @ObservedObject
    var monitoringManager: MonitoringManager

    var body: some View {

        let sendCount = monitoringManager.updateSendSuccessCount
        let successSendCount = monitoringManager.updateSendSuccessTrueCount
        let last10 = monitoringManager.last10UpdateSendSuccess

        VStack {
            HStack(spacing: 4) {
                ForEach(last10) { data in
                    Circle()
                        .fill(data.state ? Color.blue : Color.gray)
                        .frame(width: 10, height: 10)
                }
            }
            Spacer()
            Text("Batch #: \(successSendCount) / \(sendCount)")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        .clipped()
    }
}
