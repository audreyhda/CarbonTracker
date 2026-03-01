//
//  ProgressView.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI
import Charts

struct ProgressView: View {
    @EnvironmentObject var store: DataStore
    private var entryDateSet: Set<String> {
        Set(store.entries.map {
            dayFormatter.string(from: $0.date)
        }
        )
    }
    @State private var selectedTab = 0
    @State private var selectedDate = Date()
    @State private var entryToEdit: DailyEntry?
    @State private var entryToDelete: DailyEntry?
    @State private var showDeleteConfirm = false
    @State private var selectedCategoryDay: Date? = nil
    @State private var animationContainerID = UUID()

    var dailyTotals: [
        (date:Date,transport:Double,diet:Double,energy:Double,total:Double
        )] {
            store.dailyTotals
        }
    var averageTotal: Double { store.avgPerDay }
    var bestDay: Double { store.dailyTotals.map(\.total).min() ?? 0 }
    var entriesForSelectedDate: [DailyEntry] {
        store.entries.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
    var totalForSelectedDate: Double {
        entriesForSelectedDate.reduce(0) { $0 + $1.totalFootprint
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    AnimatedImage(imageName: "bee", width: 35, trueScale: 1.1, falseScale: 0.8, baseAnimation: .spring(response: 0.9, dampingFraction: 0.1),
                        slideFromRight: true)
                    StillImage(imageName: "pinkFlower")
                }
                .accessibilityHidden(true)
                .padding(.top, 50)

                Picker("View", selection: $selectedTab) {
                    Text("Chart").tag(0)
                    Text("Calendar").tag(1)
                }
                .pickerStyle(.segmented).padding(.horizontal).padding(.vertical, 10)

                if selectedTab == 0 { chartTab } else { calendarTab }
            }
            .navigationTitle("Your Progress")
            .background(Color.pastelPink.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
            .ignoresSafeArea()
            .onAppear {
                animationContainerID = UUID()
            }
            .sheet(item: $entryToEdit) { entry in LogView(editingEntry: entry).environmentObject(store) }
            .confirmationDialog("Are you sure you want to delete this entry?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let e = entryToDelete { withAnimation { store.deleteEntry(e) }; UINotificationFeedbackGenerator().notificationOccurred(.success) }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    var chartTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if store.entries.isEmpty {
                    ContentUnavailableView("No data yet", systemImage: "chart.line.downtrend.xyaxis",
                                           description: Text("Log your first day to see progress here.")).padding(.top, 60)
                } else {
                    statsRow
                    categoryAveragesCard
                    if dailyTotals.count >= 2 { categoryLineCard }
                    totalLineCard
                    AnnualRingsCard()
                }
                Spacer()
                Spacer()
                Spacer()
            }
            .padding(.horizontal).padding(.bottom, 24).padding(.top, 10)
        }
    }

    var statsRow: some View {
        HStack(spacing: 10) {
            statCapsule(icon: "flame.fill",     label: "Streak",   value: "\(store.streakDays)d",                  color: .customRed)
            statCapsule(icon: "chart.bar.fill", label: "Avg/day",  value: String(format: "%.1f kg", averageTotal), color: .customBlue)
            statCapsule(icon: "star.fill",      label: "Best day", value: String(format: "%.1f kg", bestDay),      color: .customGreen)
        }
    }

    @ViewBuilder func statCapsule(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundColor(color)
            Text(value).font(.caption.bold())
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(Color.pastelPearl.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.darkBlue, lineWidth: 1))
    }

    // MARK: Total CO₂ per day — Y axis starts at 0
    var totalLineCard: some View {
        let worldAvgLine = 12.9
        let userAvg = averageTotal

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Total CO₂ per day", systemImage: "chart.bar").font(.headline)
                Spacer()
                TooltipButton(
                    title: "Daily total CO₂",
                    message: "Your CO₂ emissions per logged day (transport + diet + energy).\n\n— Dashed green line: your personal average (\(String(format: "%.1f", userAvg)) kg/day).\n— Dashed red line: world average (~12.9 kg/day).\n\nTip: aim to keep your bars consistently below the world-average line.")
            }

            Chart {
                ForEach(dailyTotals, id: \.date) { day in
                    BarMark(x: .value("Date", day.date, unit: .day), y: .value("kg CO₂", day.total))
                        .foregroundStyle(Color.customGreen).opacity(0.6)
                        .annotation(position: .top, spacing: 4) {
                            Text(String(format: "%.1f", day.total))
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.customGreen)
                        }
                }
                RuleMark(y: .value("Your avg", userAvg))
                    .foregroundStyle(Color.customGreen.opacity(0.85))
                    .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [6, 3]))
                    .annotation(position: .trailing) {
                        Text(String(format: "avg %.1f", userAvg))
                            .font(.system(size: 8, weight: .bold)).foregroundColor(.customGreen)
                    }
                RuleMark(y: .value("World avg", worldAvgLine))
                    .foregroundStyle(Color.customRed.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 0.8, dash: [5]))
                    .annotation(position: .trailing) {
                        Text("🌍 avg").font(.caption2).foregroundColor(.customRed)
                    }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.day(), centered: true).font(.caption2)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [3]))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [3]))
                    AxisValueLabel {
                        if let x = v.as(Double.self) { Text(String(format: "%.0f", x)).font(.caption2) }
                    }
                }
            }
            .chartYScale(domain: 0 ... max((dailyTotals.map(\.total).max() ?? 20) * 1.25, worldAvgLine * 1.3))
            .chartPlotStyle { plot in plot.padding(.top, 20) }
            .frame(height: 260).id(dailyTotals.count).drawingGroup()
        }
        .padding()
        .background(Color.pastelPearl.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.darkBlue, lineWidth: 1))
    }

    // MARK: Category line card — tappable day + tooltip
    var categoryLineCard: some View {
        let maxVal = store.categoryPoints.map(\.value).max() ?? 20

        let selectedDayValues: (transport: Double, diet: Double, energy: Double)? = {
            guard let sel = selectedCategoryDay else { return nil }
            guard let match = store.dailyTotals.first(where: { Calendar.current.isDate($0.date, inSameDayAs: sel) }) else { return nil }
            return (match.transport, match.diet, match.energy)
        }()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("CO₂ by category", systemImage: "chart.line.uptrend.xyaxis").font(.headline)
                Spacer()
                TooltipButton(
                    title: "CO₂ by category",
                    message: "This chart shows your daily CO₂ breakdown across Transport, Diet, and Energy.\n\nTap anywhere on the chart to see the exact kg values for the nearest logged day. Tap again to dismiss.\n\nTransport (orange): car, plane, bus, etc.\nDiet (purple): meals and food choices.\nEnergy (blue): home electricity use."
                )
            }

            Chart(store.categoryPoints) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("kg CO₂", point.value)
                )
                .foregroundStyle(by: .value("Category", point.category))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .symbol(Circle().strokeBorder(lineWidth: 1.5))
                .symbolSize(30)

                if let sel = selectedCategoryDay,
                   Calendar.current.isDate(point.date, inSameDayAs: sel) {
                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("kg CO₂", point.value)
                    )
                    .foregroundStyle(by: .value("Category", point.category))
                    .symbolSize(100)
                }
            }
            .chartForegroundStyleScale([
                "Transport": Color.customRed,
                "Diet":      Color.customPurple,
                "Energy":    Color.customBlue
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.day(), centered: true).font(.caption2)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [3]))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [3]))
                    AxisValueLabel {
                        if let x = v.as(Double.self) { Text(String(format: "%.0f", x)).font(.caption2) }
                    }
                }
            }
            .chartYScale(domain: 0 ... max(maxVal * 1.25, 5))
            .chartPlotStyle { plot in plot.padding(.top, 8) }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .onTapGesture { location in
                            if let plotFrame = proxy.plotFrame {
                                let origin = geo[plotFrame].origin
                                let x = location.x - origin.x
                                if let tappedDate: Date = proxy.value(atX: x, as: Date.self) {
                                    let nearest = store.dailyTotals.min(by: {
                                        abs($0.date.timeIntervalSince(tappedDate)) < abs($1.date.timeIntervalSince(tappedDate))
                                    })
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if let n = nearest {
                                            if let sel = selectedCategoryDay,
                                               Calendar.current.isDate(sel, inSameDayAs: n.date) {
                                                selectedCategoryDay = nil
                                            } else {
                                                selectedCategoryDay = n.date
                                            }
                                        }
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                        }
                }
            }
            .frame(height: 200)
            .id(store.categoryPoints.count)

            // Callout for selected day
            if let sel = selectedCategoryDay, let vals = selectedDayValues {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar").font(.caption).foregroundColor(.secondary)
                        Text(sel, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                            .font(.caption.bold()).foregroundColor(.primary)
                        Spacer()
                        Button {
                            withAnimation { selectedCategoryDay = nil }
                        } label: {
                            Image(systemName: "xmark.circle.fill").font(.caption).foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    HStack(spacing: 10) {
                        categoryDetailChip(label: "Transport", value: vals.transport, color: .customRed)
                        categoryDetailChip(label: "Diet",      value: vals.diet,      color: .customPurple)
                        categoryDetailChip(label: "Energy",    value: vals.energy,    color: .customBlue)
                    }
                }
                .padding(10)
                .background(Color.pastelPearl, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.darkBlue, lineWidth: 1))
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill").font(.caption2).foregroundColor(.secondary)
                    Text("Tap a day on the chart to see the breakdown")
                        .font(.caption2).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color.pastelPearl.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.darkBlue, lineWidth: 1))
    }

    @ViewBuilder
    private func categoryDetailChip(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%.2f kg", value)).font(.caption.bold()).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    var categoryAveragesCard: some View {
        let n = Double(max(dailyTotals.count, 1))
        let avgTransport = dailyTotals.map(\.transport).reduce(0,+) / n
        let avgDiet = dailyTotals.map(\.diet).reduce(0,+)      / n
        let avgEnergy = dailyTotals.map(\.energy).reduce(0,+)    / n
        let tot  = avgTransport + avgDiet + avgEnergy
        return VStack(alignment: .leading, spacing: 12) {
            Label("Average daily breakdown", systemImage: "chart.pie").font(.headline)
            VStack(spacing: 20) {
                BreakdownRow(icon: "car.fill",   label: "Transport", value: avgTransport, total: tot, color: .customRed,    backgroundColor: .pastelOrange)
                BreakdownRow(icon: "fork.knife", label: "Diet", value: avgDiet, total: tot, color: .customPurple, backgroundColor: .pastelPurple)
                BreakdownRow(icon: "bolt.fill",  label: "Energy", value: avgEnergy, total: tot, color: .customBlue,   backgroundColor: .pastelGray)
            }
            HStack(spacing: 4) {
                Image(systemName: "info.circle").font(.caption2).foregroundColor(.secondary)
                Text("Averages across all \(dailyTotals.count) logged day\(dailyTotals.count==1 ? "" : "s").").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.pastelPearl.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.darkBlue, lineWidth: 1))
    }

    var calendarTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                CustomCalendar(selectedDate: $selectedDate, entryDateSet: entryDateSet)
                    .padding(.horizontal, 8).padding(.top, 4)
                    .background(Color.pastelPearl.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.darkBlue, lineWidth: 1))

                if !entriesForSelectedDate.isEmpty {
                    dayHeader
                    ForEach(entriesForSelectedDate) { entryCard($0) }
                } else {
                    emptyDayCard
                }
                Spacer()
                Spacer()
                Spacer()
            }
            .padding(.top, 20)
            .padding(.horizontal)
        }
    }

    struct CustomCalendar: View {
        @Binding var selectedDate: Date
        let entryDateSet: Set<String>
        @State private var currentMonth: Date = Date()
        private let calendar = Calendar.current
        private let dayFormatter: DateFormatter = {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
        }()
        private let weekdays = [
            "M", "T", "W", "T", "F", "S", "S"
        ]

        var body: some View {
            VStack(spacing: 4) {
                HStack {
                    Button { withAnimation { currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)! } } label: {
                        Image(systemName: "chevron.left").font(.subheadline).foregroundColor(.darkBlue)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text(currentMonth, format: .dateTime.month().year()).font(.subheadline).foregroundColor(.darkBlue)
                    Spacer()
                    Button { withAnimation { currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)! } } label: {
                        Image(systemName: "chevron.right").font(.subheadline).foregroundColor(.darkBlue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)

                HStack(spacing: 0) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day).font(.caption2).frame(maxWidth: .infinity).foregroundColor(.secondary)
                    }
                }

                let days = daysInMonth(for: currentMonth)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 3) {
                    ForEach(0..<days.count, id: \.self) { index in
                        if let date = days[index] {
                            dayCell(for: date)
                        } else {
                            Color.clear.aspectRatio(1, contentMode: .fill)
                        }
                    }
                }
            }
            .padding(.vertical, 3)
        }

        private func daysInMonth(for date: Date) -> [Date?] {
            guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
            let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
            let firstColumn = (firstWeekday + 5) % 7
            let daysInMonth = calendar.range(of: .day, in: .month, for: date)!.count
            var days: [Date?] = Array(repeating: nil, count: firstColumn)
            for day in 1...daysInMonth {
                if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                    days.append(dayDate)
                }
            }
            while days.count % 7 != 0 { days.append(nil) }
            return days
        }

        @ViewBuilder
        private func dayCell(for date: Date) -> some View {
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
            let hasEntry = entryDateSet.contains(dayFormatter.string(from: date))
            let day = calendar.component(.day, from: date)
            Button { selectedDate = date } label: {
                VStack(spacing: 1) {
                    Text("\(day)").font(.caption2)
                        .foregroundColor(isSelected ? .white : .primary)
                        .frame(width: 26, height: 26)
                        .background(isSelected ? Color.blue : Color.clear)
                        .clipShape(Circle())
                    if hasEntry {
                        Circle().fill(Color.blue).frame(width: 3, height: 3)
                    } else {
                        Color.clear.frame(width: 3, height: 3)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    var dayHeader: some View {
        HStack(spacing: 12) {
            let level = ImpactLevel.from(total: totalForSelectedDate)
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedDate, format: .dateTime.weekday(.wide).day().month(.wide)).font(.subheadline).foregroundColor(.secondary)
                Text(String(format: "%.1f kg CO₂", totalForSelectedDate)).font(.title2.bold()).foregroundColor(level.color)
            }
            Spacer()
            Text(level.displayName).font(.caption.bold())
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(level.color.opacity(0.15)).foregroundColor(level.color).clipShape(Capsule())
        }
        .padding()
        .background(Color.pastelPearl.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.darkBlue, lineWidth: 1))
    }

    @ViewBuilder func entryCard(_ entry: DailyEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "clock").font(.caption2).foregroundColor(.secondary)
                    Text(entry.date, format: .dateTime.hour().minute()).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text(String(format: "%.2f kg CO₂", entry.totalFootprint)).font(.subheadline.bold())
                    .foregroundColor(ImpactLevel.from(total: entry.totalFootprint).color)
            }
            VStack(spacing: 6) {
                miniBreakdownRow(icon:"car.fill",   label:"Transport", value:entry.transportFootprint, total:entry.totalFootprint, color:.customRed,    bgColor:.pastelOrange)
                miniBreakdownRow(icon:"fork.knife", label:"Diet",      value:entry.dietFootprint,      total:entry.totalFootprint, color:.customPurple, bgColor:.pastelBlue)
                miniBreakdownRow(icon:"bolt.fill",  label:"Energy",    value:entry.energyFootprint,    total:entry.totalFootprint, color:.customBlue,   bgColor:.pastelGray)
            }
            if !entry.notes.isEmpty {
                Divider()
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "note.text").font(.caption).foregroundColor(.customPurple)
                    Text(entry.notes).font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            Divider()
            HStack(spacing: 12) {
                Button { entryToEdit = entry } label: {
                    Label("Edit", systemImage: "pencil").font(.caption.bold()).foregroundColor(.customBlue)
                        .padding(.horizontal, 14).padding(.vertical, 6).background(Color.customBlue.opacity(0.1)).clipShape(Capsule())
                }.buttonStyle(.plain)
                Button { entryToDelete = entry; showDeleteConfirm = true } label: {
                    Label("Delete", systemImage: "trash").font(.caption.bold()).foregroundColor(.customOrange)
                        .padding(.horizontal, 14).padding(.vertical, 6).background(Color.customOrange.opacity(0.1)).clipShape(Capsule())
                }.buttonStyle(.plain)
                Spacer()
            }
        }
        .padding()
        .background(Color.pastelPearl.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.darkBlue, lineWidth: 1))
    }

    @ViewBuilder func miniBreakdownRow(icon: String, label: String, value: Double, total: Double, color: Color, bgColor: Color = Color.clear) -> some View {
        let proportion = total > 0 ? value / total : 0
        HStack(spacing: 8) {
            Image(systemName: icon).font(.caption2).foregroundColor(color).frame(width: 14)
            Text(label).font(.caption2).foregroundColor(.secondary).frame(width: 60, alignment: .leading)
            RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.25)).frame(height: 5)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(color).frame(height: 5)
                        .scaleEffect(x: proportion, anchor: .leading)
                }
            Text(String(format: "%.2f", value)).font(.caption2.bold()).foregroundColor(color).frame(width: 34, alignment: .trailing)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(bgColor, in: RoundedRectangle(cornerRadius: 8))
    }

    var emptyDayCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf").font(.largeTitle).foregroundColor(.blue.opacity(0.4))
            Text("No entry logged").font(.headline).foregroundColor(.secondary)
            Text(selectedDate, format: .dateTime.weekday(.wide).day().month(.wide)).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(40)
        .background(Color.pastelPearl.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.darkBlue, lineWidth: 1))
    }

    struct AnnualRingsCard: View {
        @EnvironmentObject var store: DataStore

        private let worldAnnual = 12.9 * 365
        private let euAnnual    = 19.2 * 365
        private let usAnnual    = 37.8 * 365

        private var ytdTotal: Double {
            let calendar = Calendar.current
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: Date()))!
            return store.entries
                .filter { $0.date >= startOfYear }
                .reduce(0) { $0 + $1.totalFootprint }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Year‑to‑date", systemImage: "circle.dashed").font(.headline)
                    Spacer()
                    TooltipButton(
                        title: "Year‑to‑date comparison",
                        message: "Your CO₂ logged so far this year compared to one year of average emissions in each region.\n\n🌍 World: \(Int(worldAnnual)) kg\n🇪🇺 EU: \(Int(euAnnual)) kg\n🇺🇸 US: \(Int(usAnnual)) kg\n\nNote: This comparison is most meaningful if you log your emissions every day. If you miss days, your year‑to‑date total will be lower than your actual emissions."
                    )
                }

                HStack {
                    Text("Your CO₂ this year:").font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                    Text(formatLargeNumber(ytdTotal)).font(.title2.bold()).foregroundColor(.customGreen)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Color.customGreen.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 10))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    co2DataRing(label: "You",       value: ytdTotal, co2Data: store.projectedAnnual, color: .customGreen, co2DataLabel: "your year")
                    co2DataRing(label: "World avg", value: ytdTotal, co2Data: worldAnnual,color: .customRed, co2DataLabel: "world avg")
                    co2DataRing(label: "EU avg",    value: ytdTotal, co2Data: euAnnual, color: .customBlue, co2DataLabel: "EU avg")
                    co2DataRing(label: "US avg",    value: ytdTotal, co2Data: usAnnual, color: .customOrange, co2DataLabel: "US avg")
                }
            }
            .padding()
            .background(Color.pastelPearl.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.darkBlue, lineWidth: 1))
        }

        @ViewBuilder
        private func co2DataRing(label: String, value: Double, co2Data: Double, color: Color, co2DataLabel: String) -> some View {
            let percentage = co2Data > 0 ? min(value / co2Data, 1.0) : 0
            VStack(spacing: 6) {
                ZStack {
                    Circle().stroke(color.opacity(0.2), lineWidth: 10).frame(width: 70, height: 70)
                    Circle()
                        .trim(from: 0, to: percentage)
                        .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 70, height: 70).rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text(String(format: "%.0f%%", percentage * 100)).font(.caption.bold()).foregroundColor(color)
                        Text(co2DataLabel).font(.system(size: 8)).foregroundColor(.secondary)
                            .lineLimit(1).minimumScaleFactor(0.5)
                    }
                }
                Text(label).font(.caption2).foregroundColor(.secondary)
            }
        }

        private func formatLargeNumber(_ kg: Double) -> String {
            kg >= 1000 ? String(format: "%.2f t", kg / 1000) : String(format: "%.0f kg", kg)
        }
    }
}

