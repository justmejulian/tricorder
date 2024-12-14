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

                    Toggle(
                        isOn: Binding<Bool>(
                            get: { self.settingsArray.first!.useHighFrequencySensor },
                            set: { self.settingsArray.first!.useHighFrequencySensor = $0 }
                        )
                    ) {
                        Text("Use High Frequency Sensor")
                    }
                    .toggleStyle(.switch)

                    if !settings.useHighFrequencySensor {
                        SettingsDropdown(
                            title: "Accelerometer Recording Rate",
                            maxValue: 200,
                            step: 50,
                            value: Binding<Int>(
                                get: { self.settingsArray.first!.accelerometerRecordingRate },
                                set: { self.settingsArray.first!.accelerometerRecordingRate = $0 }
                            )
                        )

                        SettingsDropdown(
                            title: "Device Motion Recording Rate",
                            maxValue: 200,
                            step: 50,
                            value: Binding<Int>(
                                get: { self.settingsArray.first!.deviceMotionRecordingRate },
                                set: { self.settingsArray.first!.deviceMotionRecordingRate = $0 }
                            )
                        )

                    }
                    
                    let keys = settings.motionSensors.keys.sorted {
                        $0.rawValue < $1.rawValue
                    }

                    ForEach(keys, id: \.self) { key in
                        Toggle(
                            isOn: Binding<Bool>(
                                get: { self.settingsArray.first!.motionSensors[key] ?? false },
                                set: { self.settingsArray.first!.motionSensors[key] = $0 }
                            )
                        ) {
                            Text("Record \(key.rawValue)")
                        }
                        .toggleStyle(.switch)
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
