// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TricorderKit",
    platforms: [.iOS(.v18), .watchOS(.v11)],
    products: [
        .library(name: "WorkoutCore", targets: ["WorkoutCore"]),
        .library(name: "PhoneWorkout", targets: ["PhoneWorkout"]),
        .library(name: "WatchWorkout", targets: ["WatchWorkout"]),
    ],
    targets: [
        .target(name: "WorkoutCore"),
        .target(name: "PhoneWorkout", dependencies: ["WorkoutCore"]),
        .target(name: "WatchWorkout", dependencies: ["WorkoutCore"]),
        .testTarget(name: "WorkoutCoreTests", dependencies: ["WorkoutCore"]),
    ],
    swiftLanguageModes: [.v6]
)
