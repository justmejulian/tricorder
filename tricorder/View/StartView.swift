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

                StartStopRecordingButton(
                    connectivityMetaInfoManager: recordingManager.connectivityManager
                        .connectivityMetaInfoManager
                )
            }
            .padding()
            .navigationBarTitle(Text("Tricorder"), displayMode: .inline)
            .navigationBarItems(
                leading:
                    HStack {
                        Button(action: {
                            print("Info button tapped!")
                        }) {
                            Image(systemName: "gear")
                        }
                    },
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
            Task {
                await recordingManager.reset()
                triggerAuthorization.toggle()
                await recordingManager.workoutManager.retrieveRemoteSession()
                await recordingManager.fetchRemoteRecordingState()
            }
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
