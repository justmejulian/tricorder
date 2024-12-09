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
                List {
                    SettingsDropdown(
                        title: "failRate",
                        maxValue: 100,
                        step: 50,
                        value: settings.failRate
                    )

                    ForEach(Array(settings.motionSensorRecodingRates.keys), id: \.self) { key in
                        SettingsDropdown(
                            title: key.rawValue,
                            maxValue: getMaxMotionsensorRecordingRate(sensorName: key),
                            step: 50,
                            value: settings.motionSensorRecodingRates[key] ?? 0
                        )
                    }
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

extension SettingsView {
    struct SettingsDropdown: View {
        let title: String
        let maxValue: Int
        let step: Int

        @State var value: Int
        var body: some View {
            HStack {
                Text(title)
                TextField(
                    "\(value)",
                    text: Binding<String>(
                        get: { String(value) },
                        set: { value = Int($0) ?? 0 }
                    )
                )
            }
        }
    }
}
