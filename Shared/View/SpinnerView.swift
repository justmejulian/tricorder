//
//  SpinnerView.swift
//  tricorder
//
//  Created by Julian Visser on 15.11.2024.
//

import SwiftUI

struct SpinnerView: View {
    var text: String?

    var body: some View {
        ProgressView(label: {
            Text(text ?? "Loading")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        ).progressViewStyle(.circular)
    }
}
