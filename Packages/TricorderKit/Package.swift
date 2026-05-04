// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TricorderKit",
    platforms: [.iOS(.v18), .watchOS(.v11), .macOS(.v15)],
    products: [
        .library(name: "Util", targets: ["Util"]),
        .library(name: "WorkoutCore", targets: ["WorkoutCore"]),
        .library(name: "PhoneWorkout", targets: ["PhoneWorkout"]),
        .library(name: "WatchWorkout", targets: ["WatchWorkout"]),
    ],
    targets: [
        .target(name: "Util"),
        .target(name: "WorkoutCore", dependencies: ["Util"]),
        .target(name: "PhoneWorkout", dependencies: ["WorkoutCore", "Util"]),
        .target(name: "WatchWorkout", dependencies: ["WorkoutCore", "Util"]),
        .testTarget(name: "WorkoutCoreTests", dependencies: ["WorkoutCore"]),
        .testTarget(name: "WatchWorkoutTests", dependencies: ["WatchWorkout", "WorkoutCore"]),
        .testTarget(name: "PhoneWorkoutTests", dependencies: ["PhoneWorkout", "WorkoutCore"]),
    ],
    swiftLanguageModes: [.v6]
)
