/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that provides a shared logger.
*/

import Foundation
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
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

    // Usage:
    //  Logger.shared.debug("run on Thread \(Thread.current)")
    internal func debug(
        _ message: @autoclosure () -> String,
        _ file: String = #file,
        _ function: String = #function,
        line: Int = #line
    ) {
        let converted =
            (file as NSString).lastPathComponent + ": " + function + ": "
            + "\(message())"
        self.debug(_:)("\(converted)")
    }
}
