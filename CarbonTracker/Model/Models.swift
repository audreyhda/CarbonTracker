//
//  Models.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI
import SwiftData

@Model
final class DailyEntry {
    var id: UUID
    var date: Date
    var transportFootprint: Double
    var dietFootprint: Double
    var energyFootprint: Double
    var notes: String

    var totalFootprint: Double {
        transportFootprint + dietFootprint + energyFootprint
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        transportFootprint: Double,
        dietFootprint: Double,
        energyFootprint: Double,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.transportFootprint = transportFootprint
        self.dietFootprint = dietFootprint
        self.energyFootprint = energyFootprint
        self.notes = notes
    }
}

@Model
final class Challenge {
    var id: UUID
    var name: String
    var challengeDescription: String
    var icon: String
    var category: String
    var isCompleted: Bool
    var isActive: Bool
    var completionDates: [Date]
    var impactKg: Double
    var activatedDate: String

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        icon: String,
        category: String,
        isCompleted: Bool = false,
        isActive: Bool = false,
        completionDates: [Date] = [],
        impactKg: Double = 0,
        activatedDate: String = ""
    ) {
        self.id = id
        self.name = name
        self.challengeDescription = description
        self.icon = icon
        self.category = category
        self.isCompleted = isCompleted
        self.isActive = isActive
        self.completionDates = completionDates
        self.impactKg = impactKg
        self.activatedDate = activatedDate
    }
}

struct CategoryPoint: Identifiable {
    var id: String {
        "\(date.timeIntervalSince1970)-\(category)"
    }
    let date: Date
    let category: String
    let value: Double
}

let dayFormatter: DateFormatter = {
    let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"; return formatter
}()

