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
    var mostRecent: T?

    var count = 0
}

extension ObservableValueManager {
    func reset() {

        count = 0
        mostRecent = nil
    }

    func update(_ newValues: [T]) {

        count += newValues.count
        mostRecent = newValues.last
    }
}
