//
//  ErrorAlertProvider.swift
//  tricorder
//
//  Created by Julian Visser on 10.02.2025.
//

import SwiftUI

struct ErrorAlertProvider {
    static func errorAlert(alertManager: AlertManager) -> Alert {
        let message = Text(alertManager.message ?? "An error occurred")
        let primaryButton = alertManager.primaryButton ?? .default(Text("OK"))

        if let secondaryButton = alertManager.secondaryButton {
            return Alert(
                title: Text("Error"),
                message: message,
                primaryButton: primaryButton,
                secondaryButton: secondaryButton
            )
        }

        return Alert(
            title: Text("Error"),
            message: message,
            dismissButton: primaryButton
        )
    }
}
