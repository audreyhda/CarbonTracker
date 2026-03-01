//
//  CarbonTrackerApp.swift
//  CarbonTracker
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import SwiftUI
import SwiftData

@main
struct SwiftStudentChallenge2026App: App {
    @StateObject private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
