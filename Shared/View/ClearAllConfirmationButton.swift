//
//  ClearAllConfirmationButton.swift
//
//  Created by Julian Visser on 01.12.2024.
//

import OSLog
import SwiftUI

struct ClearAllConfirmationButton<Label: View>: View {
    let callback: () -> Void

    @EnvironmentObject var recordingManager: RecordingManager

    @ViewBuilder let label: Label

    @State private var showConfirmation = false
    @State private var loading = false

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
                    loading = true
                    do {
                        try await recordingManager.clearAllFromDatabase()
                    } catch {
                        Logger.shared.error("\(error)")
                    }
                    loading = false

                    callback()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .overlay {
            if loading {
                SpinnerView(text: "Loading")
            }
        }
    }
}
