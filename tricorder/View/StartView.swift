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
        VStack {
            StartStopRecordingButtonView()
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
                    print("\(success) for authorization")
                case .failure(let error):
                    print("\(error) for authorization")
                }
            }
        )
    }
}
