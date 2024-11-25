//
//  RecordingListView.swift
//
//  Created by Julian Visser on 24.11.2024.
//

import Foundation
import SwiftData
import SwiftUI

struct RecordingListView: View {
    @Query(sort: \RecordingDatabaseModel.startTimestamp) var recordings: [RecordingDatabaseModel]

    var body: some View {
        List(recordings) { recording in
            VStack {
                Text(recording.name)
                Text(recording.startTimestamp.ISO8601Format()).font(.caption)
            }
        }
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
