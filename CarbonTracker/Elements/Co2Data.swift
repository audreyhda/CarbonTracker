//
//  Co2Data.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI

struct CO2Data: Identifiable {
    var id: String { label }
    let label: String; let value: Double; let color: Color; let emoji: String
}

extension CO2Data {
    static let co2Data: [CO2Data] = [
        .init(label: "You", value: 0, color: .customGreen, emoji: "🫵"),
        .init(label: "EU avg", value: 19.2, color: .customBlue, emoji: "🇪🇺"),
        .init(label: "World avg", value: 12.9, color: .customRed, emoji: "🌍"),
        .init(label: "US avg", value: 37.8, color: .customOrange, emoji: "🇺🇸"),
    ]
}


