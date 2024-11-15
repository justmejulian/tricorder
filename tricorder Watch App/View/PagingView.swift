/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout metric and controls as two pages.
*/

import SwiftUI
import os

struct PagingView: View {
    @EnvironmentObject var recordingManager: RecordingManager
    @Environment(\.isLuminanceReduced) var isLuminanceReduced

    @State private var selection: Tab = .metrics
    @State private var isSheetActive = false

    private enum Tab {
        case controls, metrics, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            SettingsView().tag(Tab.settings)
            ControlsView(
                connectivityMetaInfoManager: recordingManager.connectivityManager
                    .connectivityMetaInfoManager
            ).tag(Tab.controls)
            RecodingTimelineView().tag(Tab.metrics)
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
            Logger.shared.debug(
                "PagingView.onChange: Session state changed to \(newValue.rawValue)"
            )

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
