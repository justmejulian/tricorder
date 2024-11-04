/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows a button to start the watchOS app.
*/

import HealthKit
import HealthKitUI
import SwiftUI
import os

struct StartView: View {
    @EnvironmentObject var recordingManager: RecordingManager
    @State private var isFullScreenCoverActive = false
    @State private var triggerAuthorization = false

    var body: some View {
        NavigationView {
            VStack {
                RecodingTimelineView()

                Spacer()
                Spacer()

                StartStopRecordingButton()
            }
            .padding()
            .navigationBarTitle(Text("Tricoder"), displayMode: .inline)
            .navigationBarItems(
                trailing:
                    HStack {
                        Button(action: {
                            print("Info button tapped!")
                        }) {
                            Image(systemName: "list.bullet")
                        }
                    }
            )
        }
        .onAppear {
            triggerAuthorization.toggle()
            recordingManager.workoutManager.retrieveRemoteSession()
        }
        .healthDataAccessRequest(
            store: recordingManager.workoutManager.healthStore,
            shareTypes: recordingManager.workoutManager.typesToShare,
            readTypes: recordingManager.workoutManager.typesToRead,
            trigger: triggerAuthorization,
            completion: { result in
                switch result {
                case .success(let success):
                    print("StartView: \(success) for authorization")
                case .failure(let error):
                    print("StartView: \(error) for authorization")
                }
            }
        )
    }
}
