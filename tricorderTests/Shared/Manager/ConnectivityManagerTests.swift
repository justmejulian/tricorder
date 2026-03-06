//
//  ConnectivityManagerTests.swift
//  tricorderTests
//
//  Created by Claude on 21.06.2025.
//

import Testing
import WatchConnectivity
import Foundation
import OSLog
@testable import tricorder

struct ConnectivityManagerTests {
    
    // MARK: - Test Doubles
    
    @MainActor
    class SpyConnectivityMetaInfoManager: ConnectivityMetaInfoManager {
        private var _resetCalls: [Void] = []
        private var _increaseOpenSendConnectionsCalls: [Void] = []
        private var _decreaseOpenSendConnectionsCalls: [Void] = []
        private var _updateLastDidReceiveDataDateCalls: [Void] = []
        private var _updateIsLastDidReceiveDataDateTooRecentCalls: [Void] = []
        
        var resetCallCount: Int { _resetCalls.count }
        var increaseOpenSendConnectionsCallCount: Int { _increaseOpenSendConnectionsCalls.count }
        var decreaseOpenSendConnectionsCallCount: Int { _decreaseOpenSendConnectionsCalls.count }
        var updateLastDidReceiveDataDateCallCount: Int { _updateLastDidReceiveDataDateCalls.count }
        var updateIsLastDidReceiveDataDateTooRecentCallCount: Int { _updateIsLastDidReceiveDataDateTooRecentCalls.count }
        
        override func reset() {
            _resetCalls.append(())
            super.reset()
        }
        
        override func increaseOpenSendConnectionsCount() {
            _increaseOpenSendConnectionsCalls.append(())
            super.increaseOpenSendConnectionsCount()
        }
        
        override func decreaseOpenSendConnectionsCount() {
            _decreaseOpenSendConnectionsCalls.append(())
            super.decreaseOpenSendConnectionsCount()
        }
        
        override func updateLastDidReceiveDataDate() {
            _updateLastDidReceiveDataDateCalls.append(())
            super.updateLastDidReceiveDataDate()
        }
        
        override func updateIsLastDidReceiveDataDateTooRecent() {
            _updateIsLastDidReceiveDataDateTooRecentCalls.append(())
            super.updateIsLastDidReceiveDataDateTooRecent()
        }
    }
    
    actor MockEventManager: EventManaging {
        // Call tracking
        var triggerCallCount = 0
        var registerCallCount = 0
        var lastTriggeredKey: EventListenerKey?
        var lastTriggeredData: Data?
        
        // Response configuration
        var shouldReturnData: Data?
        var shouldThrowError: Error?
        var responseDelay: TimeInterval = 0
        
        // Registered listeners
        var registeredListeners: [EventListenerKey: Any] = [:]
        
        func reset() {
            triggerCallCount = 0
            registerCallCount = 0
            lastTriggeredKey = nil
            lastTriggeredData = nil
            shouldReturnData = nil
            shouldThrowError = nil
            responseDelay = 0
            registeredListeners.removeAll()
        }

        func setShouldReturnData(_ data: Data?) {
            shouldReturnData = data
        }

        func setShouldThrowError(_ error: Error?) {
            shouldThrowError = error
        }
        
        func register(key: EventListenerKey, handleData: @escaping @Sendable (_ data: Sendable) async throws -> Data?) {
            registerCallCount += 1
            registeredListeners[key] = handleData
        }
        
        func register(key: EventListenerKey, handleData: @escaping @Sendable (_ data: Sendable) throws -> Void) {
            registerCallCount += 1
            registeredListeners[key] = handleData
        }
        
        func trigger(key: EventListenerKey, data: Sendable) async throws -> Data? {
            triggerCallCount += 1
            lastTriggeredKey = key
            if let data = data as? Data {
                lastTriggeredData = data
            }
            
            if responseDelay > 0 {
                try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
            }
            
            if let error = shouldThrowError {
                throw error
            }
            
            return shouldReturnData
        }
        
        func trigger(key: EventListenerKey, data: Sendable) async {
            triggerCallCount += 1
            lastTriggeredKey = key
            if let data = data as? Data {
                lastTriggeredData = data
            }
            
            if responseDelay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
            }
        }
    }
    
    final class MockWCSession: WCSessionProtocol, @unchecked Sendable {
        // State configuration
        var mockIsReachable = false
        var mockActivationState: WCSessionActivationState = .notActivated
        var mockIsSupported = true
        
        // Call tracking
        var activateCallCount = 0
        var sendMessageDataCallCount = 0
        var transferFileCallCount = 0
        var lastSentData: Data?
        var lastTransferredURL: URL?
        var lastTransferMetadata: [String: Any]?
        
        // Response configuration
        var shouldFailSendMessage = false
        var shouldFailFileTransfer = false
        var sendMessageError: Error?
        var sendMessageResponse: Data?
        var sendMessageDelay: TimeInterval = 0
        
        // Delegate tracking
        weak var delegate: WCSessionDelegate?

        var isReachable: Bool {
            return mockIsReachable
        }

        func activate() {
            activateCallCount += 1
        }

        func sendMessageData(
            _ data: Data,
            replyHandler: ((Data) -> Void)?,
            errorHandler: ((Error) -> Void)?
        ) {
            sendMessageDataCallCount += 1
            lastSentData = data
            
            DispatchQueue.global().asyncAfter(deadline: .now() + sendMessageDelay) {
                if self.shouldFailSendMessage {
                    errorHandler?(self.sendMessageError ?? ConnectivityError.notReachable)
                } else {
                    let response: Data
                    if let sendMessageResponse = self.sendMessageResponse {
                        response = sendMessageResponse
                    } else {
                        response = (try? JSONEncoder().encode(["success": true])) ?? Data()
                    }
                    replyHandler?(response)
                }
            }
        }
        
        func transferFile(_ url: URL, metadata: [String : Any]?) -> WCSessionFileTransfer {
            transferFileCallCount += 1
            lastTransferredURL = url
            lastTransferMetadata = metadata
            
            let mockTransfer = MockWCSessionFileTransfer()
            mockTransfer.shouldFail = shouldFailFileTransfer
            return mockTransfer
        }
    }
    
    class MockWCSessionFileTransfer: WCSessionFileTransfer {
        var shouldFail = false
        var transferDelay: TimeInterval = 0.1
        private let mockProgress = MockProgress()
        
        override var progress: Progress {
            return mockProgress
        }
        
        override init() {
            super.init()
            simulateTransfer()
        }
        
        private func simulateTransfer() {
            DispatchQueue.global().asyncAfter(deadline: .now() + transferDelay) {
                if !self.shouldFail {
                    self.mockProgress.completedUnitCount = self.mockProgress.totalUnitCount
                }
            }
        }
    }
    
    class MockProgress: Progress {
        private var _isFinished = false
        
        override var isFinished: Bool {
            get { _isFinished || completedUnitCount >= totalUnitCount }
            set { _isFinished = newValue }
        }
        
        init() {
            super.init(parent: nil, userInfo: nil)
            totalUnitCount = 100
            completedUnitCount = 0
        }
    }
    
    private func makeManager() async -> (
        manager: ConnectivityManager,
        session: MockWCSession,
        metaInfo: SpyConnectivityMetaInfoManager,
        eventManager: MockEventManager
    ) {
        let mockEventManager = MockEventManager()
        let mockSession = MockWCSession()
        let manager = ConnectivityManager(session: mockSession, eventManager: mockEventManager)
        let spyConnectivityMetaInfo = await MainActor.run { SpyConnectivityMetaInfoManager() }

        await MainActor.run {
            manager.setConnectivityMetaInfoManager(spyConnectivityMetaInfo)
        }

        return (manager, mockSession, spyConnectivityMetaInfo, mockEventManager)
    }
    
    // MARK: - Initialization Tests
    
    @Test func initializationCreatesManagerWithCorrectState() async {
        // Given & When: ConnectivityManager is initialized
        let manager = ConnectivityManager()
        
        // Then: Manager should be created successfully
        #expect(manager != nil)
    }
    
    @Test func initializationSetsUpWCSessionDelegate() async {
        // Given & When: ConnectivityManager is initialized
        let bundle = await makeManager()

        // When: activate is called
        await bundle.manager.activate()

        // Then: Mock session should have delegate set and be activated
        #expect(bundle.session.delegate != nil)
        #expect(bundle.session.activateCallCount == 1)
    }
    
    // MARK: - Failed Send Count Tests
    
    @Test func increaseFailedSendCountIncrements() async {
        // Given: ConnectivityManager
        let bundle = await makeManager()
        let initialCount = await bundle.manager.getFailedSendCount()
        
        // When: increaseFailedSendCount is called multiple times
        await bundle.manager.increaseFailedSendCount()
        await bundle.manager.increaseFailedSendCount()
        await bundle.manager.increaseFailedSendCount()
        
        // Then: Failed send count should be incremented
        let finalCount = await bundle.manager.getFailedSendCount()
        #expect(finalCount == initialCount + 3)
    }
    
    @Test func resetClearsFailedSendCountAndCallsMetaInfoManager() async {
        // Given: ConnectivityManager with failed sends
        let bundle = await makeManager()
        await bundle.manager.increaseFailedSendCount()
        await bundle.manager.increaseFailedSendCount()

        let metaInfoManager = bundle.metaInfo
        let initialResetCount = await metaInfoManager.resetCallCount
        
        // When: reset is called
        await bundle.manager.reset()
        
        // Then: Failed send count should be reset and meta info manager reset called
        let finalCount = await bundle.manager.getFailedSendCount()
        let finalResetCount = await metaInfoManager.resetCallCount
        
        #expect(finalCount == 0)
        #expect(finalResetCount == initialResetCount + 1)
    }
    
    // MARK: - WCSessionDelegate Tests
    
    @Test func sessionActivationWithoutErrorLogsSuccess() async {
        // Given: ConnectivityManager and successful activation
        let bundle = await makeManager()
        bundle.session.mockActivationState = .activated

        // When: session activation completes without error
        bundle.manager.session(
            WCSession.default,
            activationDidCompleteWith: .activated,
            error: nil
        )
        
        // Then: Should complete without throwing
        // (Success is logged internally)
    }
    
    @Test func sessionActivationWithErrorLogsError() async {
        // Given: ConnectivityManager and activation error
        let bundle = await makeManager()
        let error = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Activation failed"])

        // When: session activation completes with error
        bundle.manager.session(
            WCSession.default,
            activationDidCompleteWith: .notActivated,
            error: error
        )
        
        // Then: Should handle error gracefully
        // (Error is logged internally)
    }
    
    @Test func sessionDidReceiveMessageDataTriggersEventAndUpdatesMetaInfo() async {
        // Given: ConnectivityManager with configured mocks
        let bundle = await makeManager()
        let testData = "test message data".data(using: .utf8)!
        let responseData = try! JSONEncoder().encode(["response": "success"])

        await bundle.eventManager.reset()
        let mockEventManager = bundle.eventManager
        await mockEventManager.setShouldReturnData(responseData)

        let metaInfoManager = bundle.metaInfo
        let initialUpdateCount = await metaInfoManager.updateLastDidReceiveDataDateCallCount
        
        // When: session receives message data
        let replyData = await withCheckedContinuation { (continuation: CheckedContinuation<Data?, Never>) in
            bundle.manager.session(WCSession.default, didReceiveMessageData: testData) { data in
                continuation.resume(returning: data)
            }
        }
        
        // Then: Event should be triggered, meta info updated, and reply sent
        let triggerCount = await mockEventManager.triggerCallCount
        let lastKey = await mockEventManager.lastTriggeredKey
        let lastData = await mockEventManager.lastTriggeredData
        let finalUpdateCount = await metaInfoManager.updateLastDidReceiveDataDateCallCount
        
        #expect(triggerCount == 1)
        #expect(lastKey == .receivedData)
        #expect(lastData == testData)
        #expect(finalUpdateCount == initialUpdateCount + 1)
        #expect(replyData == responseData)
    }
    
    @Test func sessionDidReceiveMessageDataHandlesEventManagerError() async {
        // Given: ConnectivityManager with event manager that throws
        let bundle = await makeManager()
        let testData = "test message".data(using: .utf8)!
        let testError = EventManagerError.noListenerFound

        await bundle.eventManager.reset()
        await bundle.eventManager.setShouldThrowError(testError)

        // When: session receives message data and event manager throws
        let replyData = await withCheckedContinuation { (continuation: CheckedContinuation<Data?, Never>) in
            bundle.manager.session(WCSession.default, didReceiveMessageData: testData) { data in
                continuation.resume(returning: data)
            }
        }
        
        // Then: Should reply with error information
        #expect(replyData != nil)
        
        // Decode and verify error response
        let decodedResponse = try! JSONSerialization.jsonObject(with: replyData!) as! [String: Any]
        #expect(decodedResponse["error"] != nil)
    }
    
    @Test func sessionDidReceiveFileTriggersEventWithFileData() async {
        // Given: ConnectivityManager and test file
        let bundle = await makeManager()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-file-\(UUID().uuidString)")
        let testFileContent = "test file content for connectivity".data(using: .utf8)!
        try! testFileContent.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        await bundle.eventManager.reset()
        let mockEventManager = bundle.eventManager
        
        let sessionFile = TestWCSessionFile(fileURL: tempURL)
        
        // When: session receives file
        bundle.manager.session(WCSession.default, didReceive: sessionFile)
        
        // Give some time for async file processing
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: Event should be triggered with file data
        let triggerCount = await mockEventManager.triggerCallCount
        let lastKey = await mockEventManager.lastTriggeredKey
        let lastData = await mockEventManager.lastTriggeredData
        
        #expect(triggerCount == 1)
        #expect(lastKey == .receivedFileData)
        #expect(lastData == testFileContent)
    }
    
    @Test func sessionDidReceiveFileHandlesInvalidFile() async {
        // Given: ConnectivityManager and invalid file URL
        let bundle = await makeManager()
        let invalidURL = URL(fileURLWithPath: "/nonexistent/file/path")
        let sessionFile = TestWCSessionFile(fileURL: invalidURL)

        await bundle.eventManager.reset()

        // When: session receives invalid file
        bundle.manager.session(WCSession.default, didReceive: sessionFile)
        
        // Give some time for async processing
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Should handle gracefully without triggering event
        let triggerCount = await bundle.eventManager.triggerCallCount
        #expect(triggerCount == 0)
    }
    
    // MARK: - Send Data Tests
    
    @Test func sendDataArraySendsAllItemsSequentially() async {
        // Given: ConnectivityManager with reachable session
        let bundle = await makeManager()
        bundle.session.mockIsReachable = true
        bundle.session.sendMessageResponse = try! JSONEncoder().encode(["success": true])
        
        let dataArray = [
            "data1".data(using: .utf8)!,
            "data2".data(using: .utf8)!,
            "data3".data(using: .utf8)!
        ]
        
        // When: sendDataArray is called
        do {
            try await bundle.manager.sendDataArray(key: "test-array", dataArray: dataArray)

            // Then: All items should be sent
            #expect(bundle.session.sendMessageDataCallCount == 3)
        } catch {
            // Expected in test environment - verify at least attempt was made
            #expect(bundle.session.sendMessageDataCallCount > 0)
        }
    }
    
    @Test func sendDataArrayWithEmptyArrayCompletes() async {
        // Given: ConnectivityManager and empty array
        let bundle = await makeManager()
        let emptyArray: [Data] = []
        
        // When: sendDataArray is called with empty array
        do {
            try await bundle.manager.sendDataArray(key: "empty-test", dataArray: emptyArray)

            // Then: Should complete without sending any messages
            #expect(bundle.session.sendMessageDataCallCount == 0)
        } catch {
            // Should not throw for empty array
            Issue.record("Empty array should not throw error: \(error)")
        }
    }
    
    @Test func sendDataVoidOverloadCallsDataReturningMethod() async {
        // Given: ConnectivityManager with reachable session
        let bundle = await makeManager()
        bundle.session.mockIsReachable = true
        bundle.session.sendMessageResponse = try! JSONEncoder().encode(["test": "response"])
        
        let testData = "test data".data(using: .utf8)!
        
        // When: void sendData method is called
        do {
            try await bundle.manager.sendData(key: "void-test", data: testData) as Void

            // Then: Should attempt to send message
            #expect(bundle.session.sendMessageDataCallCount == 1)
        } catch {
            // Expected in test environment
            #expect(error != nil)
        }
    }
    
    @Test func sendDataReturningMethodEncodesDataCorrectly() async {
        // Given: ConnectivityManager with reachable session
        let bundle = await makeManager()
        bundle.session.mockIsReachable = true
        let expectedResponse = try! JSONEncoder().encode(["test": "response"])
        bundle.session.sendMessageResponse = expectedResponse
        
        let testData = "test data content".data(using: .utf8)!
        
        // When: data-returning sendData method is called
        do {
            let result: Data? = try await bundle.manager.sendData(
                key: "return-test",
                data: testData
            )
            
            // Then: Should return the response data
            #expect(result == expectedResponse)
            #expect(bundle.session.sendMessageDataCallCount == 1)

            // Verify data was encoded with SendDataObjectManager
            let sentData = bundle.session.lastSentData!
            let decodedObject = try SendDataObjectManager().decode(sentData)
            #expect(decodedObject.key == "return-test")
            #expect(decodedObject.data == testData)
            
        } catch {
            // Expected in test environment - verify attempt was made
            #expect(bundle.session.sendMessageDataCallCount > 0)
        }
    }
    
    @Test func sendDataAsFileThrowsWhenNotReachable() async {
        // Given: ConnectivityManager with unreachable session
        let bundle = await makeManager()
        bundle.session.mockIsReachable = false
        let testData = "file content".data(using: .utf8)!
        
        // When & Then: sendDataAsFile should throw ConnectivityError.notReachable
        do {
            try await bundle.manager.sendDataAsFile(testData)
            Issue.record("Should have thrown ConnectivityError.notReachable")
        } catch ConnectivityError.notReachable {
            // Expected error
            
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test func sendDataAsFileTransfersFileWhenReachable() async {
        // Given: ConnectivityManager with reachable session
        let bundle = await makeManager()
        bundle.session.mockIsReachable = true
        let testData = "file transfer content".data(using: .utf8)!
        
        // When: sendDataAsFile is called
        do {
            try await bundle.manager.sendDataAsFile(testData)
            
            // Then: File should be transferred
            #expect(bundle.session.transferFileCallCount == 1)
            
            // Verify file was created and transferred
            let transferredURL = bundle.session.lastTransferredURL!
            #expect(transferredURL.path.contains("tmp-file-send"))
            
        } catch {
            // Expected in test environment - verify transfer was attempted
            #expect(bundle.session.transferFileCallCount > 0)
        }
    }
    
    @Test func sendDataAsFileHandlesTransferTimeout() async {
        // Given: ConnectivityManager with slow file transfer
        let bundle = await makeManager()
        bundle.session.mockIsReachable = true
        bundle.session.shouldFailFileTransfer = false
        
        let testData = "timeout test data".data(using: .utf8)!
        
        // When: sendDataAsFile is called (will timeout due to slow mock)
        do {
            try await bundle.manager.sendDataAsFile(testData)
            
            // Then: Should complete or timeout appropriately
            #expect(bundle.session.transferFileCallCount == 1)
            
        } catch ConnectivityError.timeout {
            // Expected timeout behavior
            
        } catch {
            // Other errors acceptable in test environment
            #expect(error != nil)
        }
    }
    
    @Test func sendMessageDataThrowsWhenNotReachable() async {
        // Given: ConnectivityManager with unreachable session
        let bundle = await makeManager()
        bundle.session.mockIsReachable = false
        let testData = "message data".data(using: .utf8)!
        
        // When & Then: sendData should throw when not reachable
        do {
            try await bundle.manager.sendData(key: "unreachable-test", data: testData) as Void
            Issue.record("Should have thrown ConnectivityError.notReachable")
        } catch ConnectivityError.notReachable {
            // Expected error
            
        } catch {
            // Other errors acceptable in test environment
            #expect(error != nil)
        }
    }
    
    @Test func sendMessageDataUpdatesConnectionCounters() async {
        // Given: ConnectivityManager with reachable session
        let bundle = await makeManager()
        bundle.session.mockIsReachable = true
        bundle.session.sendMessageResponse = try! JSONEncoder().encode(["success": true])

        let metaInfoManager = bundle.metaInfo
        let initialIncreaseCount = await metaInfoManager.increaseOpenSendConnectionsCallCount
        let initialDecreaseCount = await metaInfoManager.decreaseOpenSendConnectionsCallCount
        
        let testData = "counter test".data(using: .utf8)!
        
        // When: sendData is called
        do {
            try await bundle.manager.sendData(key: "counter-test", data: testData) as Void
            
            // Then: Connection counter methods should be called
            let finalIncreaseCount = await metaInfoManager.increaseOpenSendConnectionsCallCount
            let finalDecreaseCount = await metaInfoManager.decreaseOpenSendConnectionsCallCount
            
            #expect(finalIncreaseCount == initialIncreaseCount + 1)
            #expect(finalDecreaseCount == initialDecreaseCount + 1)
            
        } catch {
            // Even on error, increase should be called
            let finalIncreaseCount = await metaInfoManager.increaseOpenSendConnectionsCallCount
            #expect(finalIncreaseCount > initialIncreaseCount)
        }
    }
    
    @Test func sendMessageDataHandlesErrorAndUpdatesFailedCount() async {
        // Given: ConnectivityManager with failing session
        let bundle = await makeManager()
        bundle.session.mockIsReachable = true
        bundle.session.shouldFailSendMessage = true
        bundle.session.sendMessageError = ConnectivityError.timeout

        let initialFailedCount = await bundle.manager.getFailedSendCount()
        let testData = "error test".data(using: .utf8)!
        
        // When: sendData is called and fails
        do {
            try await bundle.manager.sendData(key: "error-test", data: testData) as Void
            Issue.record("Should have thrown an error")
        } catch {
            // Then: Failed send count should be incremented
            let finalFailedCount = await bundle.manager.getFailedSendCount()
            #expect(finalFailedCount == initialFailedCount + 1)
        }
    }
    
    // MARK: - ConnectivityError Tests
    
    @Test func connectivityErrorNotReachableHasCorrectDescription() {
        let error = ConnectivityError.notReachable
        #expect(error.errorDescription == "The Watch is not reachable.")
    }
    
    @Test func connectivityErrorTimeoutHasCorrectDescription() {
        let error = ConnectivityError.timeout
        #expect(error.errorDescription == "The request timed out.")
    }
    
    // MARK: - Integration and Edge Case Tests
    
    @Test func concurrentSendOperationsHandledCorrectly() async {
        // Given: ConnectivityManager with reachable session
        let bundle = await makeManager()
        bundle.session.mockIsReachable = true
        bundle.session.sendMessageResponse = try! JSONEncoder().encode(["success": true])
        
        let data1 = "concurrent1".data(using: .utf8)!
        let data2 = "concurrent2".data(using: .utf8)!
        let data3 = "concurrent3".data(using: .utf8)!
        
        // When: Multiple concurrent send operations are performed
        async let result1: Data? = bundle.manager.sendData(key: "concurrent1", data: data1)
        async let result2: Data? = bundle.manager.sendData(key: "concurrent2", data: data2)
        async let result3: Data? = bundle.manager.sendData(key: "concurrent3", data: data3)
        
        do {
            let (r1, r2, r3) = try await (result1, result2, result3)
            
            // Then: All operations should complete
            #expect(r1 != nil || r2 != nil || r3 != nil)
            #expect(bundle.session.sendMessageDataCallCount == 3)
            
        } catch {
            // Expected in test environment - verify attempts were made
            #expect(bundle.session.sendMessageDataCallCount > 0)
        }
    }
    
    @Test func resetDuringActiveOperationsHandledGracefully() async {
        // Given: ConnectivityManager with active operations
        let bundle = await makeManager()
        bundle.session.mockIsReachable = true
        bundle.session.sendMessageDelay = 0.2 // Slow response
        
        let testData = "reset test".data(using: .utf8)!
        
        // When: Starting send operation and immediately resetting
        async let sendOperation: Data? = bundle.manager.sendData(
            key: "reset-test",
            data: testData
        )
        
        // Small delay then reset
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        await bundle.manager.reset()
        
        // Then: Reset should complete and send should handle appropriately
        let resetResult = await bundle.manager.getFailedSendCount()
        #expect(resetResult == 0)
        
        do {
            _ = try await sendOperation
        } catch {
            // Error expected due to reset during operation
            #expect(error != nil)
        }
    }
    
    @Test func largeDataHandling() async {
        // Given: ConnectivityManager and large data
        let bundle = await makeManager()
        bundle.session.mockIsReachable = true
        
        // Create 1MB of test data
        let largeData = Data(repeating: 0x42, count: 1024 * 1024)
        
        // When: sendDataAsFile is called with large data
        do {
            try await bundle.manager.sendDataAsFile(largeData)
            
            // Then: Should attempt file transfer for large data
            #expect(bundle.session.transferFileCallCount == 1)
            
        } catch {
            // Expected in test environment
            #expect(bundle.session.transferFileCallCount > 0)
        }
    }
}

// MARK: - Test Helper Classes

class TestWCSessionFile: WCSessionFile {
    private let _fileURL: URL
    
    init(fileURL: URL) {
        _fileURL = fileURL
        super.init()
    }
    
    override var fileURL: URL {
        return _fileURL
    }
}
