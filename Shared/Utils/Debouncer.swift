//
//  Debouncer.swift
//  tricorder
//
//  code from: https://stackoverflow.com/questions/76887491/swift-observation-framework-and-debounce
//
//  Created by Julian Visser on 15.11.2024.
//

actor Debouncer {
    private let duration: Duration
    private var isPending = false

    public init(duration: Duration) {
        self.duration = duration
    }

    public func sleep() async -> Bool {
        if isPending { return false }
        isPending = true
        try? await Task.sleep(for: duration)
        isPending = false
        return true
    }
}
