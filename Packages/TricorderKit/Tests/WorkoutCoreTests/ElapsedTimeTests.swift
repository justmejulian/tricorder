import Testing
import Foundation
@testable import WorkoutCore

@Suite("ElapsedTime")
struct ElapsedTimeTests {

    @Test func zero() {
        let now = Date()
        #expect(elapsedString(from: now, to: now) == "00:00")
    }

    @Test func oneMinute() {
        let start = Date()
        #expect(elapsedString(from: start, to: start.addingTimeInterval(60)) == "01:00")
    }

    @Test func partialMinute() {
        let start = Date()
        #expect(elapsedString(from: start, to: start.addingTimeInterval(75)) == "01:15")
    }

    @Test func beforeStart() {
        let start = Date()
        #expect(elapsedString(from: start, to: start.addingTimeInterval(-10)) == "00:00")
    }
}
