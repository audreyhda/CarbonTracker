//
//  AnimatedImage.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI

struct AnimatedImage: View {
    let imageName: String
    var width: CGFloat
    var height: CGFloat?
    var trueScale: CGFloat = 1.1
    var falseScale: CGFloat = 1.0
    var baseAnimation: Animation = .easeInOut(duration: 2)
    var repeatCount: Int = 3
    var slideFromRight: Bool = false

    @State private var isAnimating = false
    @State private var offsetX: CGFloat = 0

    var body: some View {
        if let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable().scaledToFit()
                .frame(width: width, height: height ?? width)
                .scaleEffect(isAnimating ? trueScale : falseScale)
                .offset(x: offsetX)
                .animation(baseAnimation.repeatCount(repeatCount, autoreverses: true), value: isAnimating)
                .animation(slideFromRight ? .spring(response: 0.5, dampingFraction: 0.7) : nil, value: offsetX)
                .onAppear {
                    isAnimating = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { isAnimating = true }
                    if slideFromRight {
                        offsetX = 50
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { offsetX = 0 }
                    }
                }
                .accessibilityHidden(true)
        } else {
            EmptyView()
        }
    }
}
