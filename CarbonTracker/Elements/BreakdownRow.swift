//
//  BreakdownRow.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI

struct BreakdownRow: View {
    let icon: String; let label: String; let value: Double; let total: Double; let color: Color
    var backgroundColor: Color = Color.clear
    var proportion: Double { total > 0 ? value / total : 0 }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundColor(color)
                    .frame(width: 20)
                    .accessibilityHidden(true)
                Text(label)
                    .font(.caption.bold())
                Spacer()
                Text(String(format: "%.1f kg CO₂", value))
                    .font(.caption.bold())
                    .foregroundColor(color)
                Text("(\(Int(proportion * 100))%)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 5)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.25))
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(height: 8)
                        .scaleEffect(x: proportion, anchor: .leading)
                }
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 10)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: "%@: %.1f kilograms CO₂, %d percent of total", label, value, Int(proportion * 100)))
    }
}
