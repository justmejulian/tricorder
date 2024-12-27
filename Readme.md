# Tricorder

Project contains a watchOS and iOS Application written is Swift and SwiftUI.

The aim of tricorder is to provide an easy way to collect Sensor data from the Apple Watch.

## Supported Sensors

We currently collect data from the following sensors:

| Sensor               | Max Recording Frequency (Hz) |
|----------------------|------------------------------|
| Heart Rate                    | 0.2                          |
| Ultra Wideband (Distance)     | 10                           |
| Accelerometer                 | 800                          |
| User Acceleration             | 200                          |
| Gyroscope                     | 200                          |
| Device Motion                 | 200                          |
| Gravity                       | 200                          |

## Dev

Development is done using xcode.

Navigate to this folder and open the project file using xcode.

```bash
> open tricorder.xcodeproj
```

### Style

Swift includes a Formatter and Linter.

Make sure to run both of them and fix any issues before pushing code to this repo.

```
❯ swift format -ri .
❯ swift format lint -r .
```
