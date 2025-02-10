//
//  AlertManager.swift
//
//  Created by Julian Visser on 10.02.2025.
//

import SwiftUI

class AlertManager: ObservableObject {
    @Published var title: String?
    @Published var message: String?
    @Published var primaryButton: Alert.Button?
    @Published var secondaryButton: Alert.Button?

    @Published var isOpen: Bool = false

    func configure(title: String, message: String) {
        configure(title: title, message: message, primaryButton: nil, secondaryButton: nil)
    }

    func configure(title: String, message: String, primaryButton: Alert.Button) {
        configure(
            title: title,
            message: message,
            primaryButton: primaryButton,
            secondaryButton: nil
        )
    }

    func configure(title: String, message: String, secondaryButton: Alert.Button) {
        configure(
            title: title,
            message: message,
            primaryButton: nil,
            secondaryButton: secondaryButton
        )
    }

    func configure(
        title: String,
        message: String,
        primaryButton: Alert.Button?,
        secondaryButton: Alert.Button?
    ) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.isOpen = true
    }

    func reset() {
        title = nil
        message = nil
        primaryButton = nil
        secondaryButton = nil
        self.isOpen = false
    }
}
