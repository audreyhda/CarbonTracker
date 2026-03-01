//
//  StillImage.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI

struct StillImage: View {
    let imageName: String
    var width: CGFloat = 150
    var height: CGFloat?
    
    var body: some View {
        if let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable().scaledToFit()
                .frame(width: width, height: height ?? width)
                .accessibilityHidden(true)
        } else {
            EmptyView()
        }
    }
}
