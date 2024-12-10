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
                        title: "Max Fail Rate",
                        maxValue: 100,
                        step: 5,
                        value: Binding<Int>(
                            get: { settings.failRate },
                            set: { settings.failRate = $0 }
                        )
                    )

                    let keys = settings.motionSensorRecodingRates.keys.sorted {
                        $0.rawValue < $1.rawValue
                    }

                    ForEach(keys, id: \.self) { key in
                        SettingsDropdown(
                            title: key.name,
                            maxValue: getMaxMotionsensorRecordingRate(sensorName: key),
                            step: 50,
                            value: Binding(
                                get: {
                                    self.settingsArray.first!.motionSensorRecodingRates[key] ?? 0
                                },
                                set: {
                                    self.settingsArray.first!.motionSensorRecodingRates[key] = $0
                                }
                            )
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

        var value: Binding<Int>

        var body: some View {
            HStack {
                Picker(title, selection: value) {
                    ForEach(Array(stride(from: 0, to: maxValue + 1, by: step)), id: \.self) {
                        value in
                        Text("\(value)")
                    }
                }
            }
        }
    }
}
