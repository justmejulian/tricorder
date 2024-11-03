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
            Spacer(minLength: 30)
            LabeledContent {
                ElapsedTimeView(
                    elapsedTime: elapsedTime(with: context.date),
                    showSubseconds: context.cadence == .live
                )
                .font(
                    .system(.title, design: .rounded).monospacedDigit()
                        .lowercaseSmallCaps()
                )
            } label: {
                Text("Elapsed")
            }
            .foregroundColor(.yellow)
            .font(
                .system(.title, design: .rounded).monospacedDigit()
                    .lowercaseSmallCaps()
            )
            Spacer(minLength: 15)
        }
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
