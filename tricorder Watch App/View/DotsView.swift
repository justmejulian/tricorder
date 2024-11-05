//
//  DotsView.swift
//  tricorder
//
//  Created by Julian Visser on 05.11.2024.
//

import SwiftUI

// todo add an id and only display last 10
private let data: [Bool] = [
    true,
    true,
    true,
    false,
    true,
    true,
    true,
    false,
    true,
    true,
    true,
]

struct DotsView: View {

    var body: some View {
        VStack {
            HStack(spacing: 4) {
                ForEach(data, id: \.self) { wasSuccess in
                    Circle()
                        .fill(wasSuccess ? Color.blue : Color.gray)
                        .frame(width: 10, height: 10)
                }
            }
            Spacer()
            Text("# 8 / 10")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }
}
