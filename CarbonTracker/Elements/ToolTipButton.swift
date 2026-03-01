//
//  ToolTipButton.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI

struct TooltipButton: View {
    let title: String; let message: String
    @State private var showSheet = false
    
    var body: some View {
        Button { showSheet = true } label: {
            Image(systemName: "questionmark.circle").font(.caption.bold()).foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text("Tap for more information"))
        .sheet(isPresented: $showSheet) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    Button("Done") { showSheet = false }.font(.subheadline.bold()).foregroundColor(.customGreen)
                }
                Text(message).font(.body).foregroundColor(.primary)
                Spacer()
            }
            .padding(24)
            .presentationDetents([.medium])
        }
    }
}


