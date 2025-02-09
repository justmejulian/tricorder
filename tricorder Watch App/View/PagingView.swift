/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout metric and controls as two pages.
*/

import OSLog
import SwiftUI

struct PagingView: View {
    @EnvironmentObject var recordingManager: RecordingManager
    @Environment(\.isLuminanceReduced) var isLuminanceReduced

    @State private var selection: Tab = .metrics
    @State private var isSheetActive = false
    @State private var error: Error?
    @State private var showAlert: Bool = false

    private enum Tab {
        case controls, metrics, persisted
    }

    var body: some View {
        var errorMessage: String {
            if let localizedDescription = error?.localizedDescription {
                return localizedDescription
            }

            return "Something went wrong starting the workout."
        }
        TabView(selection: $selection) {
            if !recordingManager.recordingState.isActive {
                PersistedView(
                    navigateBack: displayMetricsView
                ).tag(Tab.persisted)
            }
            ControlsView(
                connectivityMetaInfoManager: recordingManager.connectivityManager
                    .connectivityMetaInfoManager
            ).tag(Tab.controls)
            RecodingTimelineView().tag(Tab.metrics)
        }
        .alert(errorMessage, isPresented: $showAlert) {
            Button("Dismiss", role: .cancel) {}
        }
        .onAppear {
            Task {
                guard await recordingManager.workoutManager.checkAllHealthKitPermissions() else {
                    Logger.shared.debug("has all permissions")
                    return
                }
                error = WorkoutManagerError.missingPermissions
            }
        }
        .navigationTitle("Cycling")
        .navigationBarBackButtonHidden(true)
        .tabViewStyle(
            PageTabViewStyle(
                indexDisplayMode: isLuminanceReduced ? .never : .automatic
            )
        )
        .onChange(of: isLuminanceReduced) {
            displayMetricsView()
        }
        .onChange(of: recordingManager.recordingState) {
            _,
            newValue in

            if newValue == .running || newValue == .paused {
                displayMetricsView()
            }
        }.onAppear {
            Task {
                await recordingManager.workoutManager.requestAuthorization()
            }
            selection = .metrics
        }
    }

    private func displayMetricsView() {
        withAnimation {
            selection = .metrics
        }
    }
}
