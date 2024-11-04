//
//  RecordingElapsedTimeView.swift
//  tricorder
//
//  Created by Julian Visser on 03.11.2024.
//

import SwiftUI

struct RecordingElapsedTimeView: View {
    @EnvironmentObject var recordingManager: RecordingManager

    let context: TimelineViewDefaultContext

    var body: some View {
        VStack {
            Text("Elapsed")
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            ElapsedTimeView(
                elapsedTime: elapsedTime(with: context.date),
                showSubseconds: context.cadence == .live
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(
                .system(.largeTitle, design: .rounded).monospaced()
                    .lowercaseSmallCaps()
            )
        }
        .foregroundColor(.yellow)
    }
}

// MARK: - RecordingElapsedTimeView functions
//
extension RecordingElapsedTimeView {
    func elapsedTime(with contextDate: Date) -> TimeInterval {
        guard let startDate = recordingManager.startDate else {
            return 0
        }

        return contextDate.timeIntervalSince(startDate)
    }
}
