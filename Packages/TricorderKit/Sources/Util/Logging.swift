import OSLog

@available(macOS 11.0, iOS 14.0, watchOS 7.0, *)
public extension Logger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.julianvisser.tricorder"
}
