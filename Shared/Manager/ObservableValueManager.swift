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
    @Published
    var count: Int = 0

    @Published
    var mostRecent: T?
}

extension ObservableValueManager {
    func reset() {
        Logger.shared.debug("called on Thread \(Thread.current)")

        count = 0
        mostRecent = nil
    }

    func update(_ newValue: T) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        count += 1
        mostRecent = newValue
    }

    func update(data: Sendable) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        guard let newValue = data as? T else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        update(newValue)
    }
}
