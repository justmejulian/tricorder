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

    @ObservedObject
    private var alertManager = AlertManager()

    @State private var selection: Tab = .metrics
    @State private var isSheetActive = false
    @State private var showAlert: Bool = false

    private enum Tab {
        case controls, metrics, persisted
    }

    var body: some View {
        TabView(selection: $selection) {
            if !recordingManager.recordingState.isActive {
                PersistedView(
                    navigateBack: displayMetricsView
                ).tag(Tab.persisted)
            }
            ControlsView(
                connectivityMetaInfoManager: recordingManager.connectivityManager
                    .connectivityMetaInfoManager,
                alertManager: alertManager,
                showAlert: $showAlert
            ).tag(Tab.controls)
            RecodingTimelineView().tag(Tab.metrics)
        }
        .alert(
            isPresented: $alertManager.isOpen,
            content: { ErrorAlertProvider.errorAlert(alertManager: alertManager) }
        )
        .onAppear {
            Task {
                selection = .metrics
                do {
                    try await recordingManager.workoutManager.requestAuthorization()
                } catch {
                    Logger.shared.error("Failed to request authorization: \(error)")
                    alertManager.configure(
                        title: "Error",
                        message:
                            "Could not request workout authorization. Please enable it in the settings."
                    )
                }
            }
        }
        .navigationTitle("Tricorder")
        .navigationBarBackButtonHidden(true)
        .tabViewStyle(
            PageTabViewStyle(
                indexDisplayMode: isLuminanceReduced ? .never : .automatic
            )
        )
        .onChange(of: isLuminanceReduced) {
            displayMetricsView()
        }
        .onChange(of: recordingManager.recordingState) { _, newValue in
            if newValue == .running || newValue == .paused {
                displayMetricsView()
            }
        }
    }

    private func displayMetricsView() {
        withAnimation {
            selection = .metrics
        }
    }
}
