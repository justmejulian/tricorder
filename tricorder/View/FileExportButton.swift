//
//  FileExportButton.swift
//
//  Created by Julian Visser on 01.12.2024.
//

import SwiftUI
import OSLog

struct FileExportButton: View {

    let recordingStartDate: Date

    var fileName: String {
        "\(recordingStartDate.formatted(.dateTime)).json"
    }

    @State private var isExporting = false

    @State private var file: File?

    var body: some View {
        Button("Export File") {
            Task {
                let data = ["helo", "world"]
                self.file = try await FileCreator().generateJsonFile(fileName: fileName, data: data)

                // Trigger the export action
                self.isExporting = true
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: file,
            contentType: .json,  // Specify the file type
            defaultFilename: fileName
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
