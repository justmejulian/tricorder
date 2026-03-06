//
//  MonitoringManagerTests.swift
//  tricorder Watch AppTests
//

import Testing
@testable import tricorder_Watch_App

@MainActor
struct MonitoringManagerTests {

    @Test func resetClearsAllState() {
        let manager = MonitoringManager()
        manager.addUpdateSendSuccess(true)
        manager.addUpdateSendSuccess(false)
        manager.addUpdateSendSuccess(true)

        manager.reset()

        #expect(manager.updateSendSuccess.isEmpty)
        #expect(manager.updateSendSuccessTrueCount == 0)
        #expect(manager.updateSendSuccessCount == 0)
    }

    @Test func addUpdateSendSuccessTracksResults() {
        let manager = MonitoringManager()

        manager.addUpdateSendSuccess(true)
        manager.addUpdateSendSuccess(true)
        manager.addUpdateSendSuccess(false)

        #expect(manager.updateSendSuccessCount == 3)
        #expect(manager.updateSendSuccessTrueCount == 2)
    }

    @Test func last10UpdateSendSuccessLimitsToMostRecent() {
        let manager = MonitoringManager()

        for i in 0..<15 {
            manager.addUpdateSendSuccess(i % 2 == 0)
        }

        #expect(manager.last10UpdateSendSuccess.count == 10)
        #expect(manager.updateSendSuccessCount == 15)
    }

    @Test func successEntriesHaveUniqueIds() {
        let manager = MonitoringManager()
        manager.addUpdateSendSuccess(true)
        manager.addUpdateSendSuccess(true)

        let ids = manager.updateSendSuccess.map { $0.id }
        #expect(ids[0] != ids[1])
    }
}

struct CoreMotionManagerErrorTests {

    @Test func notSupportedHasCorrectDescription() {
        let error = CoreMotionManagerError.notSupported
        #expect(error.errorDescription == "Core Motion is not supported on this device.")
    }
}

struct HighFrequencyMotionManagerErrorTests {

    @Test func notSupportedHasCorrectDescription() {
        let error = HighFrequencyMotionManagerError.notSupported
        #expect(
            error.errorDescription
                == "High-frequency motion tracking is not supported on this device. Make sure to enable Motion Permissions."
        )
    }
}
