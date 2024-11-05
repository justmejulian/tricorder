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
        ElapsedTimeView(
            elapsedTime: elapsedTime(with: context.date),
            showSubseconds: context.cadence == .live
        )
        .foregroundStyle(.yellow)
        .font(
            .system(.title, design: .rounded).monospacedDigit()
                .lowercaseSmallCaps()
        )
    }
}

// MARK: - RecordingElapsedTimeView functions
//
extension RecordingElapsedTimeView {
    func elapsedTime(with contextDate: Date) -> TimeInterval {
        guard
            let elapsedTime = recordingManager.workoutManager.builder?.elapsedTime(at: contextDate)
        else {
            return 0
        }
        return elapsedTime
    }
}
