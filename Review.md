  ---
  Code Review: Tricorder

  ---
  1. High-Level Summary

  Tricorder is an iOS + watchOS paired app that streams motion sensor data (accelerometer, rotation, gravity, quaternion, heart rate) and UWB distance measurements from Apple Watch to an iPhone during a HealthKit mirrored workout session.
   The iPhone stores data in SwiftData and lets users export it as JSON. Both targets share code through a Shared/ folder with platform-specific extensions (+iOS, +watchOS).

  The architecture is a manager-heavy coordinator pattern rather than MVVM or TCA: a central RecordingManager (annotated @MainActor) owns ~7 child actors and propagates data through a global EventManager pub/sub bus. Views consume
  RecordingManager via @EnvironmentObject.

  Overall quality is solid for a v1: good use of Swift concurrency primitives, clean cross-platform structure, and thoughtful offline buffering design. However, there are several critical concurrency bugs — including a data race in the
  event bus and multiple fatalError calls in recoverable paths — that would cause crashes in production.

  ---
  2. Strengths

  - Actors used correctly and consistently. All managers are actor types; HealthKit, WatchConnectivity, and NISession delegates are all correctly marked nonisolated.
  - @ModelActor data handlers. Isolating SwiftData access to dedicated model actors (SensorBackgroundDataHandler, RecordingBackgroundDataHandler) is the right pattern.
  - Platform split via extensions, not #if os(...) soup. RecordingManager+watchOS.swift / RecordingManager+iOS.swift is clean and readable.
  - Custom FileMerger for offline buffering. The combine/compress/split pipeline is a sound engineering decision for BLE reliability.
  - Debouncer implemented as an actor. Correct, reusable, and concurrency-safe.
  - Rich LocalizedError conformance on all error types. Every error enum has a meaningful errorDescription.

  ---
  3. Issues, Ordered by Severity

  ---
  CRITICAL

  ---
  C1: Data race — EventManager.listeners is a static var on an actor

  EventManager.swift:14

  actor EventManager {
      static let shared = EventManager()
      static var listeners: [EventListenerKey: AsyncEventHandler] = [:]  // ← BUG

  Swift actors only protect instance state. static var is not protected by the actor's executor. Every concurrent call to register and trigger reads and writes this dictionary without synchronization — a confirmed data race under Swift
  Concurrency's strict model. This will cause crashes under Thread Sanitizer and unpredictable behavior at runtime.

  Fix: Make it an instance property:

  actor EventManager {
      static let shared = EventManager()
      private var listeners: [EventListenerKey: AsyncEventHandler] = [:]
      // no other changes needed — all access is already through actor methods
  }

  ---
  C2: fatalError in multiple recoverable paths

  fatalError should only appear in programmer-error paths (like init contracts). These crash a live recording session for transient failures:

  ┌─────────────────────────────────────────┬──────────────────────────────────────────────────────┐
  │                Location                 │                      Condition                       │
  ├─────────────────────────────────────────┼──────────────────────────────────────────────────────┤
  │ RecordingManager+watchOS.swift:232      │ PersistedDataHandler fails to persist a sensor batch │
  ├─────────────────────────────────────────┼──────────────────────────────────────────────────────┤
  │ RecordingManager+watchOS.swift:210      │ Empty archive after encoding (edge case)             │
  ├─────────────────────────────────────────┼──────────────────────────────────────────────────────┤
  │ SensorDatabaseModel.swift:19            │ One corrupt JSON row terminates the whole app        │
  ├─────────────────────────────────────────┼──────────────────────────────────────────────────────┤
  │ WorkoutManager+watchOS.swift:70         │ HealthKit mirroring fails (Bluetooth drop, no phone) │
  ├─────────────────────────────────────────┼──────────────────────────────────────────────────────┤
  │ RecordingBackgroundDataHandler.swift:61 │ Duplicate timestamps (clock resync)                  │
  └─────────────────────────────────────────┴──────────────────────────────────────────────────────┘

  Fix for SensorDatabaseModel (makes the consuming compactMap in SensorBackgroundDataHandler.swift:47 do its intended job):

  // Before
  var sensor: Sensor {
      do { return try JSONDecoder().decode(Sensor.self, from: sensorJson) }
      catch { fatalError("Could not decode Sensor from JSON: \(error)") }
  }

  // After
  var sensor: Sensor? {
      try? JSONDecoder().decode(Sensor.self, from: sensorJson)
  }

  Fix for WorkoutManager+watchOS.swift:67-73:

  do {
      try await session.startMirroringToCompanionDevice()
  } catch {
      Logger.shared.error("Unable to start mirrored workout: \(error)")
      throw WorkoutManagerError.failedToStartWorkout  // caller already handles this
  }

  ---
  C3: Force-unwrap on HKWorkoutSessionState(rawValue:) — potential crash

  RecordingManager+iOS.swift:82

  self.recordingState = HKWorkoutSessionState(rawValue: recordingObject.recordingState)!

  HKWorkoutSessionState(rawValue:) returns Optional. If the Watch runs a newer OS that adds a new state value, the iOS app crashes on receipt.

  Fix:

  guard let state = HKWorkoutSessionState(rawValue: recordingObject.recordingState) else {
      throw RecordingManagerError.invalidData
  }
  self.recordingState = state

  ---
  C4: sendFileData can resume its continuation twice

  ConnectivityManager.swift:195-222

  The KVO observation and the timeout Task both call continuation.resume(...) independently. If the transfer finishes and the KVO fires just as the timeout task wakes up, you get a double-resume — which is a runtime crash in Swift
  Concurrency (precondition in CheckedContinuation). Additionally, observation.invalidate() is only called in the timeout branch, so a successful transfer leaks the KVO observer.

  Fix: Use a shared flag or, better, replace the whole pattern with AsyncStream or withTaskCancellationHandler. At minimum:

  var resumed = false
  let observation = fileTransfer.progress.observe(\.isFinished, options: [.new]) { progress, _ in
      guard progress.isFinished, !resumed else { return }
      resumed = true
      observation.invalidate()  // ← clean up immediately
      Task { await self.connectivityMetaInfoManager.decreaseOpenSendConnectionsCount() }
      continuation.resume()
  }
  Task {
      try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
      guard !resumed else { return }
      resumed = true
      observation.invalidate()
      await self.connectivityMetaInfoManager.decreaseOpenSendConnectionsCount()
      continuation.resume(throwing: ConnectivityError.timeout)
  }

  ---
  C5: Listener registration races with incoming messages

  RecordingManager.swift:41-47

  init(modelContainer: ModelContainer) {
      self.modelContainer = modelContainer
      Task {              // ← unstructured task, runs after init returns
          await registerListeners()
      }
  }

  WCSession is activated in ConnectivityManager.init(), which is also called during RecordingManager.init(). A message can arrive before the Task runs its await registerListeners(). The event will fire EventManagerError.noListenerFound,
  silently logged. On a slow device or under load, this window is real.

  Fix: RecordingManager should expose an async factory or prepare() method that the app entry point awaits before displaying the root view, or alternatively register no-op listeners first and swap them once ready.

  ---
  MAJOR

  ---
  M1: Force-casts data as! Sensor and data as! Data

  RecordingManager+watchOS.swift:206, RecordingManager+iOS.swift:174

  let sensor = data as! Sensor       // watchOS handler
  let dataArray = try fileMerger.processReceivedData(data as! Data)  // iOS handler

  The event system passes Sendable through a [EventListenerKey: AsyncEventHandler] dictionary with no type information. A mismatch (programming error, future refactor) crashes silently at runtime.

  Fix:

  guard let sensor = data as? Sensor else {
      Logger.shared.error("\(#function): Expected Sensor, got \(type(of: data))")
      return
  }

  ---
  M2: LowFrequencyMotionManager rate calculation is inverted

  LowFrequencyMotionManager.swift:27-35

  func setAccelerometerUpdateInterval(_ rate: Int?) {
      manager.accelerometerUpdateInterval = 1.0 * Double(rate)   // ← WRONG
  }
  func setDeviceMotionUpdateInterval(_ rate: Int?) {
      manager.deviceMotionUpdateInterval = 1.0 * Double(rate)    // ← WRONG
  }

  CMMotionManager.accelerometerUpdateInterval is in seconds. If rate is in Hz (as Settings implies, with values like 200), the interval should be 1.0 / Double(rate) = 0.005 s. The current code sets the interval to 200 seconds — the sensor
   effectively never fires during a normal recording.

  Fix:

  manager.accelerometerUpdateInterval = 1.0 / Double(rate)

  ---
  M3: sendDataAsFile always writes to the same temp file URL

  ConnectivityManager.swift:139-141

  let fileURL = tempDirectory.appendingPathComponent("tmp-file-send")
  try data.write(to: fileURL)

  Concurrent calls from PersistedView.sendData() (which sends in a chunked loop) overwrite each other's file before transfer completes.

  Fix:

  let fileURL = tempDirectory.appendingPathComponent(UUID().uuidString)

  ---
  M4: openSendConnectionsCount increment races with the continuation

  ConnectivityManager.swift:151-177

  Task {
      await connectivityMetaInfoManager.increaseOpenSendConnectionsCount()
  }
  return try await withCheckedThrowingContinuation { ... }

  The increment fires in a detached Task. If the continuation completes (and decrements) before the increment task runs, the count goes negative, corrupting the hasOpenSendConnections UI state.

  Fix: Increment the count before entering the continuation:

  await connectivityMetaInfoManager.increaseOpenSendConnectionsCount()
  return try await withCheckedThrowingContinuation { ... }

  ---
  M5: deleteAllInstances double-deletes and has a spurious initial save()

  BackgroundDataHandlerProtocol.swift:78-90

  func deleteAllInstances<T: PersistentModel>(of modelType: T.Type) throws {
      let modelContext = createModelContext(modelContainer: modelContainer)
      try modelContext.save()               // ← freshly created context, no-op
      try modelContext.delete(model: modelType)  // batch delete
      for model in try modelContext.fetch(FetchDescriptor<T>()) {  // ← then individual delete?
          modelContext.delete(model)
      }
      try modelContext.save()
  }

  After modelContext.delete(model:) (the SwiftData batch delete API), the subsequent fetch should return zero results. The loop is redundant. The initial save() on a freshly created context does nothing.

  Fix:

  func deleteAllInstances<T: PersistentModel>(of modelType: T.Type) throws {
      let modelContext = createModelContext(modelContainer: modelContainer)
      try modelContext.delete(model: modelType)
      try modelContext.save()
  }

  ---
  M6: AlertManager has no @MainActor isolation

  AlertManager.swift:9

  class AlertManager: ObservableObject {
      @Published var isOpen: Bool = false
      // ...
      func configure(...) {
          self.isOpen = true  // ← can be called from background Task
      }
  }

  ControlsView.startRecording() calls alertManager.configure(...) from an unstructured Task {} which doesn't inherit @MainActor. Publishing @Published changes from a non-main thread causes runtime warnings and potential corruption.

  Fix: Add @MainActor:

  @MainActor
  class AlertManager: ObservableObject { ... }

  ---
  MINOR

  ---
  m1: handleReceivedDistance on watchOS uses Date() instead of startDate

  RecordingManager+watchOS.swift:247-251

  let sensor = Sensor.distance(
      .distance,
      recordingStartDate: Date(),   // ← wrong! should be `await startDate ?? Date()`
      values: [newValues]
  )

  Distance data gets a different recordingStartDate than motion data, potentially creating a second ghost recording when the iOS app routes incoming data.

  ---
  m2: NearbyInteractionManager silently emits 0 for unavailable distances

  NearbyInteractionManager.swift:152

  let value: Double = Double(firstObject.distance ?? 0)

  UWB distance can be nil while the ranging algorithm warms up. Zero is a valid but wrong distance. Emit nothing instead:

  guard let distance = firstObject.distance else { return }
  let value = Double(distance)

  ---
  m3: RecodingTimelineView pauses the timeline only for .ended, not .notStarted

  RecodingTimelineView.swift:16-19

  let schedule = MetricsTimelineSchedule(
      from: Date(),
      isPaused: recordingManager.recordingState == .ended  // misses .notStarted
  )

  The timeline runs a periodic schedule even when no recording is active, wasting CPU/battery. Should be !recordingManager.recordingState.isActive.

  ---
  m4: ControlsView calls exit(0) for a missing permission

  ControlsView.swift:63

  primaryButton: .cancel(Text("Exit")) { exit(0) }

  exit(0) bypasses the SwiftUI lifecycle and is grounds for App Store rejection. Guide the user to Settings instead:

  primaryButton: .default(Text("Open Settings")) {
      if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
      }
  }

  ---
  m5: FileMerger.splitFiles parsing is ambiguous

  FileMerger.swift:31-44

  The header-reading loop runs while offset < combinedData.count — it reads UInt32s indefinitely until the data is consumed. There's no count-of-files field in the header, so the parser can't distinguish where the header ends and file
  data begins if a data payload happens to parse as a valid size. The format needs a file-count prefix:

  [UInt32: count] [UInt32: size0] [UInt32: size1] ... [file0 bytes] [file1 bytes] ...

  ---
  m6: print() in production code

  StartView.swift:68-69

  print("StartView: \(success) for authorization")
  print("StartView: \(error) for authorization")

  Should use Logger.shared.info(...) / Logger.shared.error(...).

  ---
  m7: FileMerger.combineFiles declares fileSizes but never uses it

  FileMerger.swift:13

  var fileSizes = [UInt32]()  // ← dead code

  ---
  m8: Typos

  ┌───────────────────────────────┬──────────────────────────────────────────────┬───────────────────────┐
  │           Location            │                     Typo                     │        Correct        │
  ├───────────────────────────────┼──────────────────────────────────────────────┼───────────────────────┤
  │ EventManager.swift:75         │ endedRecroding                               │ endedRecording        │
  ├───────────────────────────────┼──────────────────────────────────────────────┼───────────────────────┤
  │ Sensor.swift:219              │ getEmpytSensorOfEach                         │ getEmptySensorOfEach  │
  ├───────────────────────────────┼──────────────────────────────────────────────┼───────────────────────┤
  │ Sensor.swift:157              │ diveds a Sensor with valueses                │ fix comment           │
  ├───────────────────────────────┼──────────────────────────────────────────────┼───────────────────────┤
  │ ConnectivityManager.swift:211 │ "30 seconds" comment but 60 nanosecond value │ fix comment           │
  ├───────────────────────────────┼──────────────────────────────────────────────┼───────────────────────┤
  │ Multiple                      │ recive                                       │ receive               │
  ├───────────────────────────────┼──────────────────────────────────────────────┼───────────────────────┤
  │ File/struct name              │ RecodingTimelineView                         │ RecordingTimelineView │
  └───────────────────────────────┴──────────────────────────────────────────────┴───────────────────────┘

  ---
  m9: Deprecated APIs

  StartView.swift:33, 44: NavigationView and .navigationBarItems are deprecated since iOS 16. Migrate to NavigationStack + .toolbar.

  ---
  m10: Recording uses Date as primary key — fragile

  RecordingBackgroundDataHandler.swift:51-55

  SwiftData predicates use == on Date, which uses floating-point time intervals. Clock adjustments or sub-millisecond precision differences could create phantom "not found" results. A UUID primary key would be more robust.

  ---
  4. Architectural and Abstraction Opportunities

  1. Replace the EventManager with typed, protocol-based injection.
  The pub/sub bus with Sendable payloads, string-keyed routing (disguised as an enum), and static mutable state is a manual reimplementation of NotificationCenter — with all the same testability and type-safety problems. Direct
  constructor injection of typed handler closures or protocols would make data flow explicit and testable:

  // Instead of EventManager.register(key: .collectedSensorValues, ...)
  actor RecordingManager {
      init(sensorHandler: @escaping @Sendable (Sensor) async throws -> Void, ...) { ... }
  }

  2. Split RecordingManager into focused coordinators.
  It currently orchestrates workout lifecycle, sensor routing, NI token exchange, offline buffering, and state sync. An async factory + smaller coordinators would be easier to reason about:
  - SessionCoordinator — workout start/stop
  - DataRouter — routes Sensor to storage and classifier
  - SyncManager — offline buffering and retry

  3. Migrate to @Observable (iOS 17+).
  ObservableValueManager<T>, MotionObservableValueManager, MonitoringManager, and AlertManager are all ObservableObject/@Published classes. @Observable (Swift 5.9) provides fine-grained observation, simpler syntax, and removes the need
  for @ObservedObject/@EnvironmentObject boilerplate.

  4. Use a typed enum for data-routing keys.
  Every switch dataObject.key { case "sensorUpdate": ... } block is a typo waiting to happen. A SendDataKey enum shared between iOS and watchOS would eliminate the magic strings:

  enum SendDataKey: String, Codable {
      case sensorUpdate, discoveryToken, settings, recordingState, startDate
  }

  5. Use UUID as recording primary key.
  Replace Date-based lookup with a UUID generated at workout start, passed via workoutManager.sendCodable(key: "recordingId", ...) alongside startDate. This decouples storage from clock precision.

  ---
  5. Swift / iOS-Specific Concerns

  Memory management:
  - WorkoutManager+iOS.swift:29: The workoutSessionMirroringStartHandler closure captures self strongly. It's never cleared in reset(). This holds a strong reference to WorkoutManager as long as healthStore lives. Should set
  healthStore.workoutSessionMirroringStartHandler = nil in reset().

  Concurrency:
  - ConnectivityManager is declared actor, but connectivityMetaInfoManager is @MainActor lazy var (line 21). Reading a @MainActor-isolated lazy var from actor-isolated code requires a context switch. Accessing it from a SwiftUI view
  (which is @MainActor) requires first await-ing the actor to enter its domain — SwiftUI's @EnvironmentObject doesn't do this. The current code likely crosses isolation boundaries without await. This needs careful restructuring.
  - Multiple nonisolated handlers (e.g., handleSessionStateChange) spawn several unstructured Tasks that race each other (RecordingManager+watchOS.swift:139-171). State changes can interleave. Structured concurrency (async let or a single
   Task with sequential steps) is safer.

  Accessibility:
  - Navigation bar buttons (Image(systemName: "gear"), Image(systemName: "list.bullet")) have no .accessibilityLabel. VoiceOver users get "image" announced.
  - MetricsView.MetricsBox should use .accessibilityElement(children: .combine) to read title+value as one unit.

  Localization:
  - All user-facing strings are hardcoded English. String(localized:) or LocalizedStringKey should be used throughout.

  Test coverage:
  - No test targets found. The global EventManager singleton, direct RecordingManager instantiation from views, and concrete-type manager references make unit testing very difficult. The @ModelActor handlers are the most testable part —
  they could be unit-tested with an in-memory ModelContainer(for: schema, configurations: .init(isStoredInMemoryOnly: true)).

  ---
  6. Prioritized Action Plan

  1. Fix the EventManager static dictionary data race (EventManager.swift:14)
  Change static var listeners to var listeners. One line, zero API change, eliminates the most severe concurrency bug.

  2. Remove fatalError from all non-init recoverable paths
  Start with SensorDatabaseModel.sensor (change to Sensor?), WorkoutManager.startWorkout() mirroring failure, and handleSensorUpdate's persist failure. These are crashes waiting for bad data or an edge case.

  3. Fix LowFrequencyMotionManager rate calculation
  Change 1.0 * Double(rate) to 1.0 / Double(rate). This is a silent data-quality bug: at rate = 200, the sensor interval is 200 seconds, so it never fires. The low-frequency mode is currently non-functional.

  4. Deduplicate the file send temp URL
  Add UUID().uuidString to the temp filename in ConnectivityManager.sendDataAsFile. Prevents concurrent batch sends from corrupting each other's transfer.

  5. Add a typed enum for data-routing keys and eliminate force-casts
  Replace magic strings ("sensorUpdate", "discoveryToken", etc.) and data as! Sensor/data as! Data force-casts with a typed enum and guard let downcasts. This eliminates an entire class of silent crash paths and makes the data flow
  auditable.
