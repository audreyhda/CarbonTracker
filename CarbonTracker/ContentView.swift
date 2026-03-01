//
//  ContentView.swift
//  CarbonTracker
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = DataStore()
    
    var body: some View {
        TabView {
            DashboardView().environmentObject(store)
                .tabItem { Label("Dashboard", systemImage: "globe.europe.africa") }
            LogView().environmentObject(store)
                .tabItem { Label("Log", systemImage: "square.and.pencil") }
            ChallengesView().environmentObject(store)
                .tabItem { Label("Challenges", systemImage: "star") }
            ProgressView().environmentObject(store)
                .tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }
        }
    }
}
