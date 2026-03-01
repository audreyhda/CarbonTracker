//
//  ImpactLevel.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI

enum ImpactLevel {
    case amazing, great, lowImpact, impacting, highImpact
    static func from(total: Double) -> ImpactLevel {
        switch total {
        case ..<2: return .amazing
        case 2..<5: return .great
        case 5..<10: return .lowImpact
        case 10..<20: return .impacting
        default: return .highImpact
        }
    }
    var displayName: String {
        switch self {
        case .amazing: return "Amazing!"
        case .great:  return "Great!"
        case .lowImpact: return "Low Impact"
        case .impacting: return "Impacting"
        case .highImpact: return "High Impact"
        }
    }
    var iconName: String {
        switch self {
        case .amazing: return "amazingEarth"
        case .great: return "happyEarth"
        case .lowImpact: return "neutralEarth"
        case .impacting: return "sadEarth"
        case .highImpact: return "sickEarth"
        }
    }
    var color: Color {
        switch self {
        case .amazing: return .customGreen
        case .great: return Color(hex: "#36CFC9")
        case .lowImpact: return .customBlue
        case .impacting: return .customRed
        case .highImpact: return .customOrange
        }
    }
}
