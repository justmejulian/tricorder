# File Syncing Plan (Watch → iOS)

## Goal
Replace real-time chunk sending with end-of-recording file syncing. Sensor data is buffered on the watch to a temp file during recording, then transferred as a single compressed file when the recording ends. If the file grows beyond 50 MB, stop recording and trigger sync.

## Architecture Overview
- Buffer all sensor updates to a temp file on the watch during recording.
- Monitor file size; if > 50 MB, stop recording to prevent runaway storage usage.
- On recording end, compress and transfer the file via `WCSession.transferFile`.
- On iOS, receive the file, decompress, decode sensors, and store to SwiftData.

## Task Breakdown

### 1) Create a Temp File Buffer Manager (watchOS)
Create a buffer manager to handle file lifecycle and appending encoded sensors.

Responsibilities:
- Create a temp file at recording start.
- Append JSON-encoded `Sensor` entries with a delimiter.
- Track current file size.
- Read and decode all sensors at recording end.
- Clean up temp file after successful transfer.

Suggested API:

```swift
actor SensorFileBuffer {
    private var fileURL: URL?
    private var fileHandle: FileHandle?
    private(set) var currentSize: Int = 0

    func startSession(recordingId: String) throws
    func append(_ sensor: Sensor) throws
    func readAllSensors() throws -> [Sensor]
    func cleanup()
}
```

Proposed location:
- `tricorder Watch App/Manager/SensorFileBuffer.swift`

### 2) Modify `RecordingManager+watchOS.swift`
Replace chunk sending with file buffering.

Changes:
- Add a `SensorFileBuffer` property.
- In `handleSensorUpdate()`:
  - Encode and append to file buffer.
  - If `currentSize > 50 MB`, stop recording.
- In `handleSessionStateChange()` when `.stopped`:
  - Read all sensors from buffer.
  - Compress and transfer via `sendDataAsFile()`.
  - Cleanup buffer on success.

Cleanup:
- Remove `MAXCHUNKSIZE` constant and chunking logic.
- Remove direct calls to `sendSensorUpdate()`.

### 3) Enhance iOS File Reception
Update `RecordingManager+iOS.swift` to consume file transfers.

Changes:
- Register handler for `.receivedFileData` if not already.
- In `handleReceivedFileData()`:
  - Decompress via `FileMerger.processReceivedData()`.
  - Decode `Sensor` values and store to `SensorDatabaseModel`.

### 4) Reuse `FileMerger`
Use existing `FileMerger` to combine/compress on watch and decompress/split on iOS.

Potential additions if needed:
- Helper to encode `[Sensor]` into `[Data]` prior to merge.

### 5) Error Handling and Retry
Handle transfer failures robustly:
- Persist compressed file for retry if transfer fails.
- Retry on next connectivity event or via manual UI.
- Clean up temp buffer only after successful transfer.

### 6) Cleanup / Remove Dead Paths
Remove or repurpose:
- Chunk-based send path in watch recording flow.
- Persisted chunk retry UI if no longer relevant.

## File Changes Summary

| File | Action | Notes |
| --- | --- | --- |
| `tricorder Watch App/Manager/SensorFileBuffer.swift` | Add | Temp file buffer management |
| `tricorder Watch App/Manager/RecordingManager+watchOS.swift` | Update | Buffer + end-of-recording transfer |
| `tricorder/Manager/RecordingManager+iOS.swift` | Update | File reception handling |
| `Shared/Utils/FileMerger.swift` | Maybe update | Only if helpers are needed |
| `tricorder Watch App/Database/PersistedDataHandler.swift` | Update | Retry storage for file transfers |
| `tricorder Watch App/View/PersistedView.swift` | Update | Retry UI for file transfers |

## Constraints and Defaults
- File size limit: 50 MB.
- Sync trigger: recording end, or when size limit exceeded.
- Buffering strategy: temp file on disk.

## Risks and Mitigations
- **Large recordings**: size threshold prevents runaway growth.
- **Transfer failures**: persist compressed file for retry.
- **Background interruptions**: temp file persists across restarts; resume sync on next launch.
