//
//  ClearAllConfirmationButton.swift
//
//  Created by Julian Visser on 01.12.2024.
//

import SwiftUI
import OSLog

struct ClearAllConfirmationButton<Label: View>: View {
    @EnvironmentObject var recordingManager: RecordingManager

    @ViewBuilder let label: Label

    @State private var showConfirmation = false

    var body: some View {
        Button(action: {
            showConfirmation = true
        }) {
            label
        }
        .confirmationDialog(
            "Are you sure you want to delete all recordings?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await recordingManager.clearAllFromDatabase()
                    } catch {
                        Logger.shared.error("\(error)")
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
