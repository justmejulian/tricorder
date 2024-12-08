//
//  SettingsView.swift
//
//  Created by Julian Visser on 08.12.2024.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var recordingManager: RecordingManager

    @Query var settingsArray: [SettingDatabaseModel]

    @State
    var loading = false

    var body: some View {
        Text("Settings")

        if let settings = settingsArray.first {
            VStack {
                Text("Fail Rate:\(settings.failRate)")
                List(Array(settings.motionSensorRecodingRates.keys), id: \.self) { key in
                    let value = settings.motionSensorRecodingRates[key] ?? 0
                    Text("\(key):\(String(value))")
                }
            }
        } else {
            // init
            Text("Creating Settings...")
                .onAppear {
                    if settingsArray.isEmpty {
                        Task {
                            loading = true
                            let modelContainer = recordingManager.modelContainer
                            let handler = SettingsBackgroundDataHandler(
                                modelContainer: modelContainer
                            )
                            do {
                                try await handler.createSettings()
                            } catch {
                                fatalError("Could not create settings: \(error)")
                            }
                            loading = false
                        }
                    }
                }

        }

    }
}
