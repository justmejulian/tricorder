//
//  RecordingListView.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData
import SwiftUI

struct RecordingListView: View {

    // todo replace with backgorund fetch
    @Query(sort: \RecordingDatabaseModel.startTimestamp) var recordings: [RecordingDatabaseModel]

    var body: some View {
        List(recordings) { recording in
            NavigationLink {
                RecordingDetailView(recordingStartTime: recording.startTimestamp)
            } label: {
                VStack {
                    Text(recording.name)
                    Text(recording.startTimestamp.ISO8601Format()).font(.caption)
                }
            }
        }
        .navigationBarItems(
            trailing:
                ClearAllConfirmationButton {
                    Image(systemName: "xmark.bin")
                }
        )
        .overlay {
            if recordings.isEmpty {
                ContentUnavailableView(
                    "No recordings yet",
                    systemImage: "recordingtape"
                )
            }
        }
    }
}
