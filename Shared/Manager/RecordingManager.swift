//
//  RecordingManager.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import HealthKit
import OSLog
import SwiftData
import SwiftUICore

@MainActor
class RecordingManager: ObservableObject {
    let eventManager: any EventManaging

    let modelContainer: ModelContainer

    let classifierManager: ClassifierManager

    // todo are these on main thread?
    let workoutManager: any WorkoutManaging
    let nearbyInteractionManager: any NearbyInteractionManaging
    let connectivityManager: any ConnectivityManaging

    @Published var recordingState: HKWorkoutSessionState = .notStarted

    @Published var startDate: Date?

    #if os(watchOS)
        let coreMotionManager: any CoreMotionManaging
        let monitoringManager: MonitoringManager
    #endif

    private var isInitialized = false

    #if os(watchOS)
        convenience init(modelContainer: ModelContainer) {
            self.init(
                modelContainer: modelContainer,
                eventManager: EventManager.shared,
                classifierManager: ClassifierManager(),
                workoutManager: WorkoutManager(),
                nearbyInteractionManager: NearbyInteractionManager(),
                connectivityManager: ConnectivityManager(),
                coreMotionManager: CoreMotionManager(),
                monitoringManager: MonitoringManager()
            )
        }

        init(
            modelContainer: ModelContainer,
            eventManager: any EventManaging,
            classifierManager: ClassifierManager,
            workoutManager: any WorkoutManaging,
            nearbyInteractionManager: any NearbyInteractionManaging,
            connectivityManager: any ConnectivityManaging,
            coreMotionManager: any CoreMotionManaging,
            monitoringManager: MonitoringManager
        ) {
            // Logger.shared.debug("creating RecordingManager on Thread \(Thread.current)")

            self.modelContainer = modelContainer
            self.eventManager = eventManager
            self.classifierManager = classifierManager
            self.workoutManager = workoutManager
            self.nearbyInteractionManager = nearbyInteractionManager
            self.connectivityManager = connectivityManager
            self.coreMotionManager = coreMotionManager
            self.monitoringManager = monitoringManager
        }
    #else
        convenience init(modelContainer: ModelContainer) {
            self.init(
                modelContainer: modelContainer,
                eventManager: EventManager.shared,
                classifierManager: ClassifierManager(),
                workoutManager: WorkoutManager(),
                nearbyInteractionManager: NearbyInteractionManager(),
                connectivityManager: ConnectivityManager()
            )
        }

        init(
            modelContainer: ModelContainer,
            eventManager: any EventManaging,
            classifierManager: ClassifierManager,
            workoutManager: any WorkoutManaging,
            nearbyInteractionManager: any NearbyInteractionManaging,
            connectivityManager: any ConnectivityManaging
        ) {
            // Logger.shared.debug("creating RecordingManager on Thread \(Thread.current)")

            self.modelContainer = modelContainer
            self.eventManager = eventManager
            self.classifierManager = classifierManager
            self.workoutManager = workoutManager
            self.nearbyInteractionManager = nearbyInteractionManager
            self.connectivityManager = connectivityManager
        }
    #endif

    func initialize() async {
        guard !isInitialized else {
            return
        }

        await connectivityManager.activate()
        await registerListeners()
        isInitialized = true
    }
}

// MARK: -  Shared functions
//
extension RecordingManager {
    func setRecordingState(newState: HKWorkoutSessionState) {
        self.recordingState = newState
    }

    func getRecordingState() -> HKWorkoutSessionState {
        return recordingState
    }

    func setStartDate(_ date: Date) {
        self.startDate = date
    }

    func reset() async {
        recordingState = .notStarted
        startDate = nil

        await classifierManager.reset()

        await connectivityManager.reset()

        resetRest()
    }

    func getFirstMissingPermission() async -> String? {
        if let missingPermission = await workoutManager.getMissingHealthKitPermission() {
            return missingPermission
        }
        if await !nearbyInteractionManager.checkIfSupported() {
            return "Nearby Interaction"
        }

        return nil
    }
}

// MARK: -  Shared handlers
//
extension RecordingManager {
}

// MARK: -  RecordingManagerError
//
enum RecordingManagerError: LocalizedError {
    case invalidData
    case noKey
    case startWorkout
    case startUpdates

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "The recorded data is invalid or corrupted."
        case .noKey:
            return "A required encryption key is missing."
        case .startWorkout:
            return "Failed to start the workout session."
        case .startUpdates:
            return "Failed to start sensor updates."
        }
    }
}
