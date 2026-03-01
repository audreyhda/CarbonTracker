//
//  DashboardView.swift
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

struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    @StateObject private var coach = TipsCoach()
    @State private var showAnnualExpanded  = false
    @State private var showAllChallenges   = false
    @State private var showImpactDetail    = false
    @State private var animationContainerID = UUID()
    @State private var isPlanetAnimating = false

    private let worldAvgDailyKg = 12.9

    var impactLevel: ImpactLevel { ImpactLevel.from(total: store.todayTotal) }
    var vsWorldAvg: Double {
        guard store.todayTotal > 0 else { return 0 }
        return ((worldAvgDailyKg - store.todayTotal) / worldAvgDailyKg) * 100
    }
    var comparisonCo2Data: [CO2Data] {
        CO2Data.co2Data.map { data in
            data.label == "You"
            ? CO2Data(label: "You", value: store.todayTotal, color: impactLevel.color, emoji: "🫵")
            : data
        }
    }
    let worldAnnual = 12.9 * 365

    var body: some View {
        NavigationStack {
            ScrollView {
                HStack {
                    AnimatedImage(
                        imageName: "cloud",
                        width: 90,
                        baseAnimation: .easeInOut(duration: 5),
                        slideFromRight: true
                    )
                    AnimatedImage(
                        imageName: "bee",
                        width: 35,
                        trueScale: 1.1,
                        falseScale: 0.8,
                        baseAnimation: .spring(response: 0.9, dampingFraction: 0.1)
                    )
                    AnimatedImage(
                        imageName: "cloud",
                        width: 60,
                        baseAnimation: .easeInOut(duration: 6),
                        slideFromRight: true
                    )
                    AnimatedImage(
                        imageName: "sun",
                        width: 100,
                        trueScale: 1.15, falseScale: 1.0,
                        baseAnimation: .easeInOut(duration: 8)
                    )
                }
                .id(animationContainerID)
                .accessibilityHidden(true)
                .padding(.top, 50)

                VStack(spacing: 18) {
                    Spacer()
                    earthCard
                        .shadow(color: impactLevel.color.opacity(0.9), radius: 12, x: 0, y: 5)
                    tipsCoachCard
                    statsCard
                    challengesCard
                    breakdownCard
                    comparisonCard
                    Spacer()
                    Spacer()
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle("Dashboard")
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .pastelBlue, .pastelPearl, .pastelPearl, .pastelPearl, .pastelGreen
                    ]),
                    startPoint: .top, endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 20)
            )
            .ignoresSafeArea()
            .onAppear {
                Task { await coach.generateAdviceOnLaunch(for: store.entries) }
                animationContainerID = UUID()
                isPlanetAnimating = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { isPlanetAnimating = true }
            }
            .onChange(of: store.entries.count) {
                if coach.advice.isEmpty {
                    Task { await coach.generateAdviceOnLaunch(for: store.entries) }
                }
            }
        }
    }

    // MARK: Hero Card
    var earthCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                if let img = UIImage(named: impactLevel.iconName) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .scaleEffect(isPlanetAnimating ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true), value: isPlanetAnimating)
                        .accessibilityLabel("Planet status: \(impactLevel.displayName)")
                } else if let fallback = UIImage(named: "happyEarth") {
                    Image(uiImage: fallback)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .scaleEffect(isPlanetAnimating ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true), value: isPlanetAnimating)
                        .accessibilityHidden(true)
                }
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, Earth Guardian")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .accessibilityAddTraits(.isHeader)
                    if store.todayTotal > 0 {
                        Text(String(format: "%.1f kg", store.todayTotal))
                            .font(.system(size: 36, weight: .semibold, design: .rounded))
                            .foregroundColor(impactLevel.color)
                        Text("CO₂ today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                        Text(impactLevel.displayName)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(impactLevel.color.opacity(0.15))
                            .foregroundColor(impactLevel.color)
                            .clipShape(Capsule())
                            .accessibilityHidden(true)
                    } else {
                        Text("No logs yet today")
                            .font(.headline)
                        Text("Tap Log to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            if store.todayTotal > 0 {
                Divider()
                HStack {
                    Image(systemName: vsWorldAvg >= 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .foregroundColor(vsWorldAvg >= 0 ? .customGreen : .customOrange)
                        .accessibilityHidden(true)
                    if vsWorldAvg >= 0 {
                        Text("You're **\(Int(vsWorldAvg))% below** the world average of \(String(format: "%.1f", worldAvgDailyKg)) kg CO₂/day").font(.subheadline)
                    } else {
                        Text("You're **\(Int(abs(vsWorldAvg)))% above** the world average of \(String(format: "%.1f", worldAvgDailyKg)) kg CO₂/day").font(.subheadline)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(Color.white.opacity(0.05)
        .clipShape(RoundedRectangle(cornerRadius: 20)))
    }

    // MARK: Stats Card
    var statsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Your stats", systemImage: "chart.bar")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                TooltipButton(
                    title: "How are these calculated?",
                    message: "Streak: consecutive days with at least one log entry.\n\nAvg/day: your total CO₂ divided by the number of days logged.\n\nProjected annual: your daily average × 365.\n\nBenchmarks (production-based, fossil CO₂, 2023):\n🌍 World avg: ~4,709 kg/year (~12.9 kg/day)\n🇪🇺 EU avg: ~7,008kg/year (~19.2 kg/day)\n🇺🇸 US avg: ~13,815 kg/year (~37.8 kg/day)\n\nNote:\n national figures include industrial emissions \n beyond personal control. \n Source: Global Carbon Project 2023 / EDGAR.")
            }
            HStack(spacing: 12) {
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.customRed)
                            .accessibilityHidden(true)
                        Text("\(store.streakDays)")
                            .font(.title2.bold())
                            .foregroundColor(.customRed)
                    }
                    Text("day streak")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.customRed.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(spacing: 6) {
                    Text(String(format: "%.1f", store.avgPerDay))
                        .font(.title2.bold())
                        .foregroundColor(.customBlue)
                    Text("kg CO₂/day avg")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.customBlue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(spacing: 6) {
                    Text(String(format: "%.0f", store.projectedAnnual))
                        .font(.title2.bold())
                        .foregroundColor(store.projectedAnnual < worldAnnual ? .customGreen : .customOrange)
                    Text("kg/year est.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background((store.projectedAnnual < worldAnnual ? Color.customGreen : Color.customOrange)
                .opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { showAnnualExpanded.toggle() }
            } label: {
                HStack {
                    Text("Annual footprint comparison")
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                    Spacer()
                    TooltipButton(
                        title: "Annual footprint",
                        message: "Your projected annual footprint vs. global benchmarks (production-based fossil CO₂, 2023).\n\n🌍 World avg: ~4,709 kg/year (~12.9 kg/day)\n🇪🇺 EU avg: ~7,008 kg/year (~19.2 kg/day)\n🇺🇸 US avg: ~13,815 kg/year (~37.8 kg/day)\n\nNote: \n these national per-capita figures include heavy industry, \n not just individual lifestyle. \n Source: Global Carbon Project 2023 (EDGAR/IEA).")
                    Image(systemName: "chevron.right")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(showAnnualExpanded ? 90 : 0))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color(.systemGray6)
                .opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            if showAnnualExpanded {
                let maxVal = max(store.projectedAnnual, worldAnnual, 14000)
                VStack(spacing: 5) {
                    annualBar(label: "You", value: store.projectedAnnual, max: maxVal, color: store.projectedAnnual < worldAnnual ? .customGreen : .customOrange)
                    annualBar(label: "World avg", value: 4709,  max: maxVal, color: .customRed)
                    annualBar(label: "EU avg", value: 7008,  max: maxVal, color: .customBlue)
                    annualBar(label: "US avg", value: 13815, max: maxVal, color: .customOrange)
                }
                .padding(.vertical, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.pastelPink.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
        .stroke(Color.darkBlue, lineWidth: 1))
        .shadow(color: Color.customYellow.opacity(0.15), radius: 12, x: 0, y: 5)
    }

    @ViewBuilder func annualBar(label: String, value: Double, max: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 55, alignment: .leading)
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.12))
                .frame(height: 10)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color).frame(height: 10)
                        .scaleEffect(x: min(value / max, 1.0), anchor: .leading)
                }
                .accessibilityHidden(true)
            Text(String(format: "%.1f t", value / 1000))
                .font(.caption2.bold())
                .foregroundColor(color)
                .frame(width: 38, alignment: .trailing)
        }
    }

    // MARK: Breakdown Card
    var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("Today's breakdown", systemImage: "chart.pie")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 10) {
                BreakdownRow(
                    icon: "car.fill",
                    label: "Transport",
                    value: store.todayTransport,
                    total: store.todayTotal,
                    color: .customRed
                )
                BreakdownRow(
                    icon: "fork.knife",
                    label: "Diet",
                    value: store.todayDiet,
                    total: store.todayTotal,
                    color: .customPurple
                )
                BreakdownRow(
                    icon: "bolt.fill",
                    label: "Energy",
                    value: store.todayEnergy,
                    total: store.todayTotal,
                    color: .customBlue
                )
            }
        }
        .padding()
        .background(Color.pastelYellow.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
        .stroke(Color.darkBlue, lineWidth: 1))
        .shadow(color: Color.customBlue.opacity(0.15), radius: 12, x: 0, y: 5)
    }

    // MARK: Comparison Card
    var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("How you compare today", systemImage: "person.3")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                TooltipButton(title: "Daily CO₂ comparison",
                              message: "Your total CO₂ today vs. the average daily footprint per person by region (production-based, fossil CO₂, 2023).\n\n🌍 World avg: ~12.9 kg/day (~4.7 t/year)\n🇪🇺 EU avg: ~19.2 kg/day (~7.0 t/year)\n🇺🇸 US avg: ~37.8 kg/day (~13.8 t/year)\n\nNote: \n national figures include heavy industry & cement, \n not just personal lifestyle. Individual lifestyle footprints are typically lower.\nSource: Global Carbon Project 2023 (Our World in Data); EDGAR/IEA 2023.")
            }
            Chart(comparisonCo2Data) { data in
                BarMark(x: .value("kg CO₂", data.value), y: .value("Group", data.label))
                    .foregroundStyle(data.color).cornerRadius(6)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text(String(format: "%.1f kg", data.value))
                            .font(.caption.bold())
                            .foregroundColor(data.color)
                    }
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    AxisValueLabel { if let x = v.as(Double.self) {
                        Text("\(Int(x))")
                            .font(.caption2)
                    } }
                }
            }
            .chartYAxis {
                AxisMarks { v in
                    AxisValueLabel {
                        if let s = v.as(String.self) {
                    Text(s)
                        .font(.caption.bold())
                } }
                }
            }
            .frame(height: 160)
        }
        .padding()
        .background(Color.pastelOrange.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
        .stroke(Color.darkBlue, lineWidth: 1))
    }

    // MARK: Coach Card
    var tipsCoachCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tips of the day", systemImage: coach.usingAI ? "apple.intelligence" : "sparkles")
                    .font(.headline)
                    .foregroundColor(.darkBlue)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                TooltipButton(
                    title: "About the Coach",
                    message: coach.usingAI
                    ? "The Coach is powered by Apple Intelligence (Foundation Models) running entirely on your device. It uses a library of evidence-based tips as inspiration and generates personalised, private advice — no internet required."
                    : "The Coach analyses your last 7 days to find your biggest emission source, then picks a tip from a curated library of evidence-based actions.\n\nOn iOS 26+, this automatically upgrades to live on-device AI via Apple Intelligence."
                )
                Button {
                    Task { await coach.generateAdvice(for: store.entries, force: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.darkBlue)
                        .clipShape(Capsule())
                }
                .disabled(coach.isLoading)
                .accessibilityLabel("Refresh eco tip")
            }
            if coach.isLoading {
                Text(coach.advice)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            } else if !coach.advice.isEmpty {
                Text(coach.advice)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Loading…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.pastelPearl.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
        .stroke(Color.darkBlue, lineWidth: 1))
        .shadow(color: Color.customGreen.opacity(0.12), radius: 12, x: 0, y: 5)
    }

    // MARK: Challenges Preview Card
    var challengesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Today's challenges", systemImage: "star")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if !store.activeChallenges.isEmpty {
                    let done = store.activeChallenges.filter(\.isCompleted).count
                    Text("\(done)/\(store.activeChallenges.count)")
                        .font(.caption.bold())
                        .foregroundColor(.customGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.customGreen.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            if store.activeChallenges.count > 3 {
                Button {
                    withAnimation { showAllChallenges.toggle() }
                } label: {
                    Label(showAllChallenges ? "Show less" : "+\(store.activeChallenges.count - 3) more",
                          systemImage: showAllChallenges ? "chevron.up" : "chevron.down")
                    .font(.caption.bold())
                    .foregroundColor(.customGreen)
                }
                .buttonStyle(.plain)
            }

            if store.activeChallenges.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.title2)
                        .foregroundColor(.customGreen
                        .opacity(0.5))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No challenges selected")
                            .font(.subheadline.bold())
                        Text("Go to the Challenges tab and tap a challenge to add it to your day.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
            } else {
                let toShow = showAllChallenges ? store.activeChallenges : Array(store.activeChallenges.prefix(3))
                ForEach(toShow) { challenge in
                    HStack(spacing: 12) {
                        Image(systemName: challenge.icon)
                            .font(.title3)
                            .foregroundColor(challenge.isCompleted ? .customGreen : .secondary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(challenge.name).font(.subheadline.bold())
                                .strikethrough(challenge.isCompleted)
                                .foregroundColor(challenge.isCompleted ? .secondary : .primary)
                            if challenge.impactKg < 0 {
                                Text("Saves ~\(String(format: "%.1f", abs(challenge.impactKg))) kg CO₂")
                                    .font(.caption2)
                                    .foregroundColor(.customGreen)
                            }
                        }
                        Spacer()
                        if challenge.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.customGreen)
                                .font(.title3)
                        } else {
                            Button("Done") {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { store.toggleChallenge(challenge)
                                }
                                UINotificationFeedbackGenerator()
                                    .notificationOccurred(.success)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.customGreen)
                            .font(.caption.bold())
                        }
                    }
                }

                if store.activeChallenges.count > 3 {
                    Button {
                        withAnimation { showAllChallenges.toggle() }
                    } label: {
                        Label(showAllChallenges ? "Show less" : "", systemImage: showAllChallenges ? "chevron.up" : "")
                            .font(.caption.bold())
                            .foregroundColor(.customGreen)
                    }
                    .buttonStyle(.plain)
                }

                let allDone = store.activeChallenges.allSatisfy(\.isCompleted)
                if !allDone {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { store.completeAllChallenges() }
                        UINotificationFeedbackGenerator()
                            .notificationOccurred(.success)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline)
                            Text("Done All")
                                .font(.subheadline.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.customGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Mark all challenges as done")
                }

                if store.totalImpactIfCompleted < 0 {
                    Divider()
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            showImpactDetail.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "leaf.circle.fill")
                                .foregroundColor(.customGreen)
                                .font(.subheadline)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Complete all → save ~\(String(format: "%.1f", abs(store.totalImpactIfCompleted))) kg CO₂ today")
                                    .font(.caption.bold())
                                    .foregroundColor(.customGreen)
                                Text("vs. a typical day without these actions")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(showImpactDetail ? 90 : 0))
                        }
                    }
                    .buttonStyle(.plain)

                    if showImpactDetail {
                        VStack(spacing: 6) {
                            ForEach(store.activeChallenges.filter { $0.impactKg < 0 }) {
                                challenge in
                                HStack(spacing: 8) {
                                    Image(systemName: challenge.icon)
                                        .font(.caption2)
                                        .foregroundColor(.customGreen)
                                        .frame(width: 18)
                                    Text(challenge.name)
                                        .font(.caption2)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("−\(String(format: "%.1f", abs(challenge.impactKg))) kg")
                                        .font(.caption2.bold())
                                        .foregroundColor(.customGreen)
                                }
                            }
                            Divider()
                            let typicalDay = store.avgPerDay
                            let projectedWithChallenges = max(0, typicalDay + store.totalImpactIfCompleted)
                            HStack(spacing: 8) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.caption2)
                                    .foregroundColor(.customBlue)
                                    .frame(width: 18)
                                Text("Typical day")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f kg", typicalDay))
                                    .font(.caption2.bold())
                                    .foregroundColor(.customBlue)
                            }
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.customGreen)
                                    .frame(width: 18)
                                Text("With all challenges")
                                    .font(.caption2.bold())
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(String(format: "%.1f kg", projectedWithChallenges))
                                    .font(.caption2.bold())
                                    .foregroundColor(.customGreen)
                            }
                        }
                        .padding(10)
                        .background(Color.customGreen.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                if !store.activeChallenges.isEmpty && store.activeChallenges.allSatisfy(\.isCompleted) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.customGreen)
                            .font(.title2)
                        Text("All done today! Amazing work 🌱")
                            .font(.subheadline.bold())
                            .foregroundColor(.customGreen)
                    }
                }
            }
        }
        .padding()
        .background(Color.pastelGreen.opacity(0.4), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
        .stroke(Color.darkBlue, lineWidth: 1))
        .shadow(color: Color.customGreen.opacity(0.15), radius: 12, x: 0, y: 5)
    }
}
