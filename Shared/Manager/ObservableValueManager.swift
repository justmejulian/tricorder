//
//  ObservableValueManager.swift
//
//  Created by Julian Visser on 02.11.2024.
//

import Foundation
import HealthKit
import OSLog

@MainActor
class ObservableValueManager<T: Value>: ObservableObject {
    // todo remove to save ram
    @Published
    var values: [T] = []

    @Published
    var mostRecent: T?

    var count: Int {
        values.count
    }
}

extension ObservableValueManager {
    func reset() {
        Logger.shared.debug("called on Thread \(Thread.current)")

        values = []
        mostRecent = nil
    }

    func update(_ newValues: [T]) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        values.append(contentsOf: newValues)

        mostRecent = newValues.last
    }
}
