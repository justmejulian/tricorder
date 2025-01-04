/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows a button to start the watchOS app.
*/

import HealthKit
import HealthKitUI
import OSLog
import SwiftUI

struct StartView: View {
    @EnvironmentObject var recordingManager: RecordingManager
    @State private var isFullScreenCoverActive = false
    @State private var triggerAuthorization = false
    @State private var isLoading = false

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
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    },

                trailing:
                    NavigationLink(destination: RecordingListView()) {
                        Image(systemName: "list.bullet")
                    }
            )
        }
        .onAppear {
            Task {
                self.isLoading = true
                await recordingManager.reset()
                triggerAuthorization.toggle()
                await recordingManager.workoutManager.retrieveRemoteSession()
                do {
                    try await recordingManager.fetchRemoteRecordingState()
                } catch {
                    Logger.shared.error("Failed to send request for recording state: \(error)")
                }
                self.isLoading = false
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
