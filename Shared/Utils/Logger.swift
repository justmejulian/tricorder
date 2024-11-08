/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that provides a shared logger.
*/

import Foundation
import os

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    #if os(watchOS)
        static let shared = Logger(
            subsystem: subsystem,
            category: "MirroringWorkoutsSampleForWatch"
        )
    #else
        static let shared = Logger(
            subsystem: subsystem,
            category: "MirroringWorkoutsSample"
        )
    #endif

    internal func debug(
        _ message: @autoclosure () -> String,
        _ file: String = #file,
        _ function: String = #function,
        line: Int = #line
    ) {
        // todo add thread?
        let converted =
            (file as NSString).lastPathComponent + ": " + function + ": "
            + "\(message())"
        self.debug(_:)("\(converted)")
    }
}
