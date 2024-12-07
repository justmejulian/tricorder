//
//  Debouncer.swift
//
//  Created by Julian Visser on 15.11.2024.
//

import OSLog

actor Debouncer {
    private let duration: Duration
    private var currentTask: Task<(), any Error>?

    public init(duration: Duration) {
        self.duration = duration
    }

    public func sleep() async -> Bool {
        // Cancel the currently pending task, if any
        currentTask?.cancel()

        // Create a new task for this debounce cycle
        let task = Task {
            try await Task.sleep(for: duration)
        }
        
        currentTask = task

        // Await the task completion or cancellation
        do {
            try await task.value
            currentTask = nil
            return true  // Completed successfully
        } catch {
            return false
        }
    }
}
