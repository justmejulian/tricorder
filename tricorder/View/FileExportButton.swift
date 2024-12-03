//
//  FileExportButton.swift
//
//  Created by Julian Visser on 01.12.2024.
//

import OSLog
import SwiftUI

struct FileExportButton: View {
    @EnvironmentObject var recordingManager: RecordingManager

    let recordingStartDate: Date

    @State private var isExporting = false

    @State private var file: File?

    var body: some View {
        Button("Export File") {
            Task {
                self.file = try await generateFile(recordingStartDate: recordingStartDate)
                // Trigger the export action
                self.isExporting = true
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: file,
            contentType: .json,
            defaultFilename: file?.fileName ?? "Untitled.json"
        ) { result in
            switch result {
            case .success(let url):
                Logger.shared.info("File exported to \(url)")
            case .failure(let error):
                Logger.shared.error("Failed to export file: \(error)")
                print("Failed to export file: \(error)")
            }
        }
    }
}

extension FileExportButton {
    func generateFile(recordingStartDate: Date) async throws -> File? {

        let modelContainer = recordingManager.modelContainer
        let recordingBackgroundDataHandler = RecordingBackgroundDataHandler(
            modelContainer: modelContainer
        )
        let sensorBackgroundDataHandler = SensorBackgroundDataHandler(
            modelContainer: modelContainer
        )

        let recording = try await recordingBackgroundDataHandler.getRecording(
            recordingStart: recordingStartDate
        )
        let sensorData = try await sensorBackgroundDataHandler.getSensors(
            recordingStart: recordingStartDate
        )

        let file = FileModel(
            name: recording.name,
            startDate: recording.startTimestamp,
            data: sensorData
        )

        return try await FileCreator().generateJsonFile(fileName: recording.name, data: file)
    }

    struct FileModel: Codable {
        let name: String
        let startDate: Date
        let data: [Sensor]
    }
}
