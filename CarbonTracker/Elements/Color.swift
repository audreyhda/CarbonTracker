//
//  Color.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI

extension Color {
    static let pastelBlue = Color(hex: "#C8E6F5")
    static let pastelGreen = Color(hex: "#C5EDD6")
    static let pastelYellow = Color(hex: "#FAF0C0")
    static let pastelOrange = Color(hex: "#F9DDD0")
    static let pastelPurple = Color(hex: "#DDD6F3")
    static let pastelGray = Color(hex: "#D6E4E0")
    static let pastelPink = Color(hex: "#F5D9E8")
    static let pastelPearl = Color(hex: "#EFF4F2")

    static let customGreen = Color(hex: "#00C875")
    static let customBlue = Color(hex: "#00AEEF")
    static let customRed = Color(hex: "#FF9F1C")
    static let customYellow = Color(hex: "#FFD166")
    static let customOrange = Color(hex: "#FF5757")
    static let customPurple = Color(hex: "#9B51E0")

    static let darkBlue = Color(hex: "#1A2744")
    static let customGray = Color(hex: "#5E7A72")

    init(hex: String) {
        let h = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: h)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue: Double( rgb & 0xFF) / 255
        )
    }
}
