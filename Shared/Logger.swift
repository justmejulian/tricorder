//
//  Logger.swift
//  tricorder
//
//  Created by Julian Visser on 05.10.2024.
//

import Foundation
import os

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    #if os(watchOS)
    static let shared = Logger(subsystem: subsystem, category: "MirroringWorkoutsSampleForWatch")
    #else
    static let shared = Logger(subsystem: subsystem, category: "MirroringWorkoutsSample")
    #endif
}
