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

    @State private var loading = false
    @State var elapsedTime: TimeInterval = 0

    var body: some View {
        ElapsedTimeView(
            elapsedTime: elapsedTime,
            showSubseconds: context.cadence == .live
        )
        .foregroundStyle(.yellow)
        .font(
            .system(.title, design: .rounded).monospacedDigit()
                .lowercaseSmallCaps()
        )
        .overlay {
            if loading {
                SpinnerView(text: "Loading")
            }
        }
        // Run task on context.date changes
        .task(id: context.date) {
            await loadData(contextDate: context.date)
        }
    }
}

// MARK: - RecordingElapsedTimeView functions
//
extension RecordingElapsedTimeView {
    func loadData(contextDate: Date) async {
        self.loading = true
        guard
            let elapsedTime = await recordingManager.workoutManager.getElapsedTime(at: contextDate)
        else {
            self.elapsedTime = 0
            self.loading = false
            return
        }
        self.elapsedTime = elapsedTime
        self.loading = false
    }
}
