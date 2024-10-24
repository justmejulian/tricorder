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
    static let shared = Logger(subsystem: subsystem, category: "MirroringWorkoutsSampleForWatch")
    #else
    static let shared = Logger(subsystem: subsystem, category: "MirroringWorkoutsSample")
    #endif
    
    /// Log calling Function name to shared Logger info
    /// ```
    /// func testFunction() {
    ///   Logger.function(); // "testFunction"
    /// }
    /// ```
    static func function() {
        self.shared.info("\(#function)")
    }
}
