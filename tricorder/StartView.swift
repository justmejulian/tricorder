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
            MirroringWorkoutView()
            Button {
                if !recordingManager.recordingState.isActive {
                    startCyclingOnWatch()
                }
            } label: {
                let title =
                recordingManager.recordingState.isActive
                    ? "View ongoing cycling" : "Start cycling on watch"
                ButtonLabel(
                    title: title, systemImage: "figure.outdoor.cycle"
                )
                .frame(width: 150, height: 150)
                .fontWeight(.medium)
            }
            .clipShape(Circle())
            .overlay {
                Circle().stroke(.white, lineWidth: 4)
            }
            .shadow(radius: 7)
            .buttonStyle(.bordered)
            .tint(.green)
            .foregroundColor(.black)
            .frame(width: 400, height: 400)
            .disabled(recordingManager.recordingState.isActive)
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

    private func startCyclingOnWatch() {
        Task {
            await recordingManager.startRecording()
        }
    }
}
