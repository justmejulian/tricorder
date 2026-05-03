@preconcurrency import HealthKit
import Foundation
@testable import WatchWorkout
import WorkoutCore

// MARK: - FakeHealthStore

// @unchecked Sendable: all mutation from @MainActor test suite.
final class FakeHealthStore: HealthStoreProtocol, @unchecked Sendable {

    let fakeSession = FakeWorkoutSession()

    private(set) var authorizationCallCount = 0
    private(set) var lastToShare: Set<HKSampleType>?
    private(set) var lastRead: Set<HKObjectType>?

    var authorizationError: Error?
    var makeSessionError: Error?

    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws {
        authorizationCallCount += 1
        lastToShare = toShare
        lastRead = read
        if let e = authorizationError { throw e }
    }

    func makeWorkoutSession(configuration: HKWorkoutConfiguration) throws -> any WorkoutSessionProtocol {
        if let e = makeSessionError { throw e }
        return fakeSession
    }
}

// MARK: - FakeWorkoutSession

// @unchecked Sendable: all mutation from @MainActor test suite.
final class FakeWorkoutSession: WorkoutSessionProtocol, @unchecked Sendable {

    private(set) weak var observer: (any WorkoutSessionObserver)?
    let fakeBuilder = FakeWorkoutBuilder()

    private(set) var prepareCallCount = 0
    private(set) var mirroringCallCount = 0
    private(set) var startActivityDates: [Date] = []
    private(set) var stopActivityDates: [Date] = []
    private(set) var endCallCount = 0

    var mirroringError: Error?

    // MARK: - WorkoutSessionProtocol

    func setObserver(_ observer: (any WorkoutSessionObserver)?) { self.observer = observer }
    func makeBuilder() -> any WorkoutBuilderProtocol { fakeBuilder }

    func prepare() { prepareCallCount += 1 }

    func startMirroringToCompanionDevice() async throws {
        mirroringCallCount += 1
        if let e = mirroringError { throw e }
    }

    func startActivity(with startDate: Date) { startActivityDates.append(startDate) }
    func stopActivity(with date: Date) { stopActivityDates.append(date) }
    func end() { endCallCount += 1 }

    // MARK: - Test helpers

    /// Fires sessionDidChangeState directly on the observer (already @MainActor).
    @MainActor
    func simulateStateChange(
        to toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState = .notStarted,
        date: Date = .now
    ) {
        observer?.sessionDidChangeState(to: toState, from: fromState, date: date)
    }

    @MainActor
    func simulateFailure(error: Error) {
        observer?.sessionDidFail(error: error)
    }
}

// MARK: - FakeWorkoutBuilder

// @unchecked Sendable: all mutation from @MainActor test suite.
final class FakeWorkoutBuilder: WorkoutBuilderProtocol, @unchecked Sendable {

    private(set) var startDate: Date? = nil
    private(set) var beginCollectionDates: [Date] = []
    private(set) var endCollectionDates: [Date] = []
    private(set) var finishWorkoutCallCount = 0

    var endCollectionError: Error?
    var finishWorkoutError: Error?

    func setObserver(_ observer: (any WorkoutBuilderObserver)?) {}

    @MainActor func beginCollection(at startDate: Date) async throws {
        self.startDate = startDate
        beginCollectionDates.append(startDate)
    }

    @MainActor func endCollection(at endDate: Date) async throws {
        endCollectionDates.append(endDate)
        if let e = endCollectionError { throw e }
    }

    @MainActor func finishWorkout() async throws {
        finishWorkoutCallCount += 1
        if let e = finishWorkoutError { throw e }
    }
}
