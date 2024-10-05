//
//  ContentView.swift
//  tricorder Watch App
//
//  Created by Julian Visser on 01.10.2024.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Tricorder")
            Text(workoutManager.sessionState.rawValue == 2 ? " Running" : " Not Running")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
