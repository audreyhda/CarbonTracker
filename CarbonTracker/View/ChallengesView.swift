//
//  ChallengesView.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif
import Charts

struct ChallengesView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedCategory = "All"
    let categories = [
        "All","transport","diet","energy","lifestyle"
    ]
    let categoryLabels: [String:String] = [
        "All":"All",
        "transport":"🚗 Transport",
        "diet":"🥗 Diet",
        "energy":"⚡ Energy",
        "lifestyle":"♻️ Lifestyle"
    ]
    let categoryColors: [String:Color] = [
        "transport":.customRed,
        "diet":.customPurple,
        "energy":.customBlue,
        "lifestyle":.customGreen
    ]

    var filtered: [Challenge] {
        selectedCategory == "All" ? store.challenges : store.challenges.filter { $0.category == selectedCategory }
    }
    var activeCount: Int {
        store.activeChallenges.count
    }
    var completedCount: Int {
        store.completedChallengeCount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                HStack {
                    Spacer()
                    StillImage(imageName: "smallTree")
                        .padding(.top, 50)
                }
                .accessibilityHidden(true)

                VStack(spacing: 16) {
                    progressHeader

                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.customGreen)
                            .font(.subheadline)
                        Text("Tap the icon to add a challenge to your day. Tap Done when you complete it.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.pastelPearl, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    VStack(spacing: 8) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { cat in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedCategory = cat }
                                    } label: {
                                        Text(categoryLabels[cat] ?? cat)
                                            .font(.caption.bold())
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(selectedCategory == cat ? (categoryColors[cat] ?? .pastelGreen) : Color.pastelPearl)
                                            .overlay(RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.darkBlue, lineWidth: 1))
                                            .foregroundColor(selectedCategory == cat ? .white : .primary)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }

                        let allActive = store.isCategoryAllActive(selectedCategory)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                store.toggleAllActive(in: selectedCategory)
                            }
                            UIImpactFeedbackGenerator(style: .medium)
                                .impactOccurred()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: allActive ? "minus.circle.fill" : "checkmark.circle.fill")
                                    .font(.subheadline)
                                Text(allActive ? "Deselect All" : "Select All")
                                    .font(.caption.bold())
                            }
                            .foregroundColor(allActive ? .customOrange : .customGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background((allActive ? Color.customOrange : Color.customGreen).opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(allActive ? Color.customOrange : Color.customGreen, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .accessibilityLabel(allActive ? "Deselect all challenges in \(categoryLabels[selectedCategory] ?? selectedCategory)" : "Select all challenges in \(categoryLabels[selectedCategory] ?? selectedCategory)")
                    }

                    if filtered.isEmpty {
                        Text("No challenges in this category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, challenge in
                                challengeRow(challenge)
                                if index < filtered.count - 1 {
                                    Divider()
                                        .padding(.leading, 74)
                                }
                            }
                        }
                        .background(Color.pastelPearl, in: RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.darkBlue, lineWidth: 1))
                        .padding(.horizontal)
                    }
                    Spacer()
                    Spacer()
                    Spacer()
                }
                .padding(.top, 8)
            }
            .navigationTitle("Challenges")
            .background(Color.pastelGreen.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
            .ignoresSafeArea()
        }
    }

    var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(activeCount) selected · \(completedCount) completed")
                        .font(.headline)
                    Text("Tap a challenge icon to add it to your day 🌱")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.customGreen
                        .opacity(0.2), lineWidth: 6)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: activeCount == 0 ? 0 : CGFloat(completedCount) / CGFloat(activeCount))
                        .stroke(Color.customGreen, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90)).frame(width: 52, height: 52)
                        .animation(.spring(), value: completedCount)
                    Text(activeCount == 0 ? "–" : "\(Int((Double(completedCount)/Double(activeCount))*100))%")
                        .font(.caption2.bold())
                        .foregroundColor(.customGreen)
                }
            }
            if activeCount > 0 && completedCount == activeCount {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill").foregroundColor(.customGreen)
                    Text("All done! You're a true Earth Steward today 🌍")
                        .font(.caption.bold())
                        .foregroundColor(.customGreen)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.customGreen.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color.pastelPearl, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
        .stroke(Color.darkBlue, lineWidth: 1))
        .padding(.horizontal)
    }

    @ViewBuilder func challengeRow(_ challenge: Challenge) -> some View {
        let color = categoryColors[challenge.category] ?? .customGreen
        HStack(spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { store.toggleActive(challenge) }
                UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(challenge.isActive ? color.opacity(0.2) : color.opacity(0.08))
                        .frame(width: 46, height: 46)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(challenge.isActive ? color : Color.clear, lineWidth: 2))
                    Image(systemName: challenge.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(challenge.isActive ? color : color.opacity(0.45))
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(challenge.name)
                        .font(.subheadline.bold())
                        .foregroundColor(challenge.isCompleted ? .secondary : challenge.isActive ? .primary : .secondary)
                        .strikethrough(challenge.isCompleted)
                    if challenge.isActive && !challenge.isCompleted {
                        Text("Today")
                            .font(.caption2.bold())
                            .foregroundColor(color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(challenge.challengeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if challenge.impactKg < 0 {
                    Text("~\(String(format: "%.1f", abs(challenge.impactKg))) kg CO₂ saved")
                        .font(.caption2.bold())
                        .foregroundColor(.customGreen)
                }
            }
            Spacer()

            if challenge.isActive {
                if challenge.isCompleted {
                    Button {
                        withAnimation(.easeInOut(duration: 0.05)) { store.toggleChallenge(challenge) }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(color)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.05)) { store.toggleChallenge(challenge) }
                        UINotificationFeedbackGenerator()
                            .notificationOccurred(.success)
                    } label: {
                        Text("Done")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(color)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.05)) { store.toggleActive(challenge) }
                    UIImpactFeedbackGenerator(style: .light)
                        .impactOccurred()
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundColor(Color(.systemGray3))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(challenge.isActive ? color.opacity(0.04) : Color.clear)
    }
}
