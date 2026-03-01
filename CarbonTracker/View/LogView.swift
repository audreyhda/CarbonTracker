//
//  LogView.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI
import Foundation
import SwiftUI
import SwiftData

@Model
final class DailyEntry {
    var id: UUID
    var date: Date
    var transportFootprint: Double
    var dietFootprint: Double
    var energyFootprint: Double
    var notes: String

    var totalFootprint: Double {
        transportFootprint + dietFootprint + energyFootprint
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        transportFootprint: Double,
        dietFootprint: Double,
        energyFootprint: Double,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.transportFootprint = transportFootprint
        self.dietFootprint = dietFootprint
        self.energyFootprint = energyFootprint
        self.notes = notes
    }
}

@Model
final class Challenge {
    var id: UUID
    var name: String
    var challengeDescription: String
    var icon: String
    var category: String
    var isCompleted: Bool
    var isActive: Bool
    var completionDates: [Date]
    var impactKg: Double
    var activatedDate: String

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        icon: String,
        category: String,
        isCompleted: Bool = false,
        isActive: Bool = false,
        completionDates: [Date] = [],
        impactKg: Double = 0,
        activatedDate: String = ""
    ) {
        self.id = id
        self.name = name
        self.challengeDescription = description
        self.icon = icon
        self.category = category
        self.isCompleted = isCompleted
        self.isActive = isActive
        self.completionDates = completionDates
        self.impactKg = impactKg
        self.activatedDate = activatedDate
    }
}

struct CategoryPoint: Identifiable {
    var id: String {
        "\(date.timeIntervalSince1970)-\(category)"
    }
    let date: Date
    let category: String
    let value: Double
}

let dayFormatter: DateFormatter = {
    let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"; return formatter
}()


struct LogView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    var editingEntry: DailyEntry?

    @State private var useKm = false
    private let kmToMiles = 0.621371

    @State private var carDistance: Double = 0;
    @State private var carIsElectric = false
    
    @State private var motoDistance: Double = 0;
    @State private var motoIsElectric = false
    
    @State private var busDistance: Double = 0;
    @State private var busIsElectric = false
    
    @State private var trainDistance: Double = 0;
    @State private var trainIsElectric = false
    
    @State private var taxiDistance: Double = 0;
    @State private var taxiIsElectric = false
    
    @State private var planeDistance: Double = 0
    @State private var metroDistance: Double = 0
    @State private var eScooterDistance: Double = 0
    @State private var bikeDistance: Double = 0

    @State private var mealsPerDay: Double = 0
    @State private var dietType: String = ""

    @State private var electricityKWh: Double = 0
    @State private var notes: String = ""
    @State private var saveSuccess = false
    @State private var expandedSection: LogSection? = .diet
    @FocusState private var focusedField: LogField?

    enum LogSection: String {
        case diet="Diet"; case energy="Energy"; case transport="Transport"; case notes="Notes"
    }
    enum LogField: Hashable {
        case car, moto, bus, train, taxi, plane, metro, eScooter, bike, electricity
    }

    func toMiles(_ v: Double) -> Double { useKm ? v * kmToMiles : v }

    let dietOptions:[
        (name:String,icon:String,description:String,color:Color)] = [
        ("Meat‑heavy","🥩","Mostly meat-based",.customOrange),
        ("Average","🍽️","Mixed meat & veggies",.customRed),
        ("Pescatarian","🐟","Fish, no red meat",.customBlue),
        ("Vegetarian","🥗","No meat, dairy OK",.customGreen),
        ("Vegan","🌱","Fully plant-based",Color(hex:"#52B87F")),
        ("Fasting","💧","No food today",.customGray),
    ]
    
    var transportTotal: Double {
        FootprintCalculator.calculateTransport(
            carMiles: toMiles(carDistance),
            carIsElectric: carIsElectric,
            motoMiles: toMiles(motoDistance),
            motoIsElectric: motoIsElectric,
            busMiles: toMiles(busDistance),
            busIsElectric: busIsElectric,
            trainMiles: toMiles(trainDistance),
            trainIsElectric: trainIsElectric,
            taxiMiles: toMiles(taxiDistance),
            taxiIsElectric: taxiIsElectric,
            planeMiles: toMiles(planeDistance),
            metroMiles: toMiles(metroDistance),
            eScooterMiles: toMiles(eScooterDistance),
            bikeMiles: toMiles(bikeDistance))
    }
    var dietTotal: Double {
        FootprintCalculator.calculateDiet(
            mealsPerDay: mealsPerDay,
            dietType: dietType)
    }
    var energyTotal: Double {
        FootprintCalculator.calculateEnergy(
            electricityKWh: electricityKWh)
    }
    var liveTotal: Double {
        transportTotal + dietTotal + energyTotal
    }
    var unitLabel:   String {
        useKm ? "km" : "mi"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    HStack {
                        Spacer()
                        StillImage(imageName: "mushs")
                            .padding(.top, 50)
                    }
                    .accessibilityHidden(true)

                    VStack(spacing: 14) {
                        HStack {
                             Spacer()
                             TooltipButton(
                                 title: "Multiple logs per day",
                                 message: "You can log as many times as you want throughout the day — each entry is added on top of the others.\n\nFor example, log your morning commute, then come back later to add your meals and evening energy use. All entries for the same day are combined on your Dashboard and Progress views."
                             )
                         }
                         .padding(.horizontal, 4)
                        sectionCard(
                            section: .diet,
                            icon: "fork.knife",
                            color: .customPurple,
                            kg: dietTotal,
                            bgColor: .pastelPurple
                        ){ AnyView(dietSection) }
                        sectionCard(
                            section: .energy,
                            icon: "bolt.fill",
                            color: .customBlue,
                            kg: energyTotal,
                            bgColor: .pastelGray
                        ){ AnyView(energySection) }
                        sectionCard(
                            section: .transport,
                            icon: "car.fill",
                            color: .customRed,
                            kg: transportTotal,
                            bgColor: .pastelOrange
                        ) { AnyView(transportSection) }
                        sectionCard(
                            section: .notes,
                            icon: "note.text",
                            color: .customBlue,
                            kg: nil,
                            bgColor: .pastelBlue
                        ){ AnyView(notesSection) }
                        
                        Color.clear.frame(height: 100)
                        
                        Spacer()
                        Spacer()
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("Log your day")
                .background(Color.pastelYellow.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
                .ignoresSafeArea()
                .scrollDismissesKeyboard(.interactively)
                floatingSaveBar
            }
        }
    }

    @ViewBuilder
    func sectionCard(section: LogSection, icon: String, color: Color, kg: Double?,
                     bgColor: Color = Color(.secondarySystemBackground),
                     content: () -> AnyView) -> some View {
        let expanded = expandedSection == section
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { expandedSection = expanded ? nil : section }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(color)
                    }
                    .accessibilityHidden(true)
                    Text(section.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    if let kg {
                        Text(kg > 0 ? String(format: "%.2f kg", kg) : "")
                            .font(.caption.bold()).foregroundColor(kg > 0 ? color : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(kg > 0 ? color.opacity(0.12) : Color.clear)
                            .clipShape(Capsule())
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            if expanded {
                Divider()
                    .padding(.horizontal, 16)
                content()
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(bgColor, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 20)
        .stroke(Color.darkBlue, lineWidth: 1))
        .shadow(color: expanded ? color.opacity(0.15) : .black.opacity(0.05), radius: expanded ? 10 : 4, x: 0, y: 3)
    }

    // MARK: Transport Section
    var transportSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("Distance unit")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("Distance unit", selection: $useKm) {
                    Text("Miles").font(.caption).tag(false)
                    Text("Km").font(.caption).tag(true)
                }
                .pickerStyle(.segmented).frame(width: 130)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color(.systemGray6)).opacity(0.5).clipShape(RoundedRectangle(cornerRadius: 10))

            transportRow(
                icon: "car.fill",
                label: "Car",
                distance: $carDistance,
                isElectric: $carIsElectric,
                field: .car
            )
            transportRow(
                icon: "bicycle",
                label: "Moto",
                distance: $motoDistance,
                isElectric: $motoIsElectric,
                field: .moto
            )
            transportRow(
                icon: "bus.fill",
                label: "Bus",
                distance: $busDistance,
                isElectric: $busIsElectric,
                field: .bus
            )
            transportRow(
                icon: "tram.fill",
                label: "Train",
                distance: $trainDistance,
                isElectric: $trainIsElectric,
                field: .train
            )
            transportRow(
                icon: "car.rear.fill",
                label: "Taxi",
                distance: $taxiDistance,
                isElectric: $taxiIsElectric,
                field: .taxi
            )

            Divider()
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.customRed.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: "airplane")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.customRed)
                }
                Text("Plane")
                    .font(.subheadline.bold())
                Spacer()
                distanceField(
                    value: $planeDistance,
                    field: .plane,
                    tint: .customRed)
                Text(unitLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 22)
                Button { } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "fuelpump.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain).disabled(true)
                .accessibilityHidden(true)
            }
            infoNote("✈️ Flights have the highest per-mile emissions of any transport.")

            Divider()
            sectionSubheader(
                label: "Low-emission modes",
                icon: "leaf.fill",
                color: .customGreen
            )
            metroRow
            eScooterRow
            bikeRow
        }
    }

    @ViewBuilder
    func sectionSubheader(label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(label)
                .font(.caption.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var metroRow: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.customRed.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: "tram.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.customRed)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Metro")
                    .font(.subheadline.bold())
                    .frame(width: 60, alignment: .leading)
                Text("~0.005 kg CO₂/mi")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            Spacer()
            distanceField(
                value: $metroDistance,
                field: .metro,
                tint: .customRed)
            Text(unitLabel)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 22)
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.customGreen)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(Color.customGreen.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.customGreen.opacity(0.4), lineWidth: 1))
        }
    }

    var eScooterRow: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.customRed.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: "scooter")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.customRed)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("E-Scooter")
                    .font(.subheadline.bold())
                    .frame(width: 80, alignment: .leading)
                Text("~0.065 kg CO₂/mi")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            Spacer()
            distanceField(
                value: $eScooterDistance,
                field: .eScooter,
                tint: .customRed)
            Text(unitLabel)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 22)
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.customGreen)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(Color.customGreen.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule()
            .stroke(Color.customGreen.opacity(0.4), lineWidth: 1))
        }
    }

    var bikeRow: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.customRed.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: "bicycle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.customRed)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Bike")
                    .font(.subheadline.bold())
                    .frame(width: 60, alignment: .leading)
                Text("~0.013 kg CO₂/mi")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            Spacer()
            distanceField(
                value: $bikeDistance,
                field: .bike,
                tint: .customRed)
            Text(unitLabel)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 22)
            HStack(spacing: 3) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.customGreen)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(Color.customGreen.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule()
                .stroke(Color.customGreen.opacity(0.4), lineWidth: 1))
        }
    }

    @ViewBuilder
    func transportRow(icon: String, label: String, distance: Binding<Double>, isElectric: Binding<Bool>, field: LogField) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isElectric.wrappedValue ? Color.customGreen.opacity(0.15) : Color.customRed.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isElectric.wrappedValue ? .customGreen : .customRed)
            }
            Text(label)
                .font(.subheadline.bold())
                .frame(width: 38, alignment: .leading)
            Spacer()
            distanceField(value: distance, field: field, tint: isElectric.wrappedValue ? .customGreen : .customRed)
            Text(unitLabel).font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 22)
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isElectric.wrappedValue.toggle() }
                UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: isElectric.wrappedValue ? "bolt.fill" : "fuelpump.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(isElectric.wrappedValue ? .customGreen : .customRed)
                    Image(systemName: isElectric.wrappedValue ? "checkmark" : "")
                        .font(.system(size: 7))
                        .opacity(0)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(isElectric.wrappedValue ? Color.customGreen.opacity(0.15) : Color.customRed.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule()
                    .stroke(isElectric.wrappedValue ? Color.customGreen.opacity(0.4) : Color.customRed.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    func distanceField(value: Binding<Double>, field: LogField, tint: Color = .customRed) -> some View {
        HStack(spacing: 3) {
            Button {
                if value.wrappedValue >= 1 { value.wrappedValue = max(0, value.wrappedValue - 1); UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred() }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(value.wrappedValue > 0 ? tint : Color.gray.opacity(0.4))
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)

            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center).focused($focusedField, equals: field)
                .frame(width: 46)
                .padding(.horizontal, 4)
                .padding(.vertical, 5)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .font(.subheadline.bold())

            Button {
                value.wrappedValue += 1; UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(tint)
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
        }
    }

    var dietSection: some View {
        VStack(spacing: 14) {
            Text("What best describes your diet today?")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(dietOptions, id: \.name) { option in dietCard(option: option) }
            }
            if !dietType.isEmpty && dietType != "Fasting" {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Meals today")
                            .font(.subheadline.bold())
                        Text("How many meals did you eat?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Stepper("Meals today", value: $mealsPerDay, in: 1...10, step: 1).labelsHidden()
                    Text("\(Int(mealsPerDay))")
                        .font(.title3.bold())
                        .foregroundColor(.customPurple)
                        .frame(width: 28)
                }
            }
            if dietType.isEmpty {
                infoNote("👆 Pick your diet type above.")
            } else if dietType == "Fasting" {
                infoNote("💧 Fasting = 0 kg CO₂ from food today. Great for the planet!")
            } else if let factor = FootprintCalculator.dietFactors[dietType] {
                infoNote("🍽️ \(dietType) ≈ \(String(format: "%.1f", factor)) kg CO₂/meal \(Int(mealsPerDay)) meal\(mealsPerDay == 1 ? "" : "s") = \(String(format: "%.2f", dietTotal)) kg today")
            }
        }
    }

    @ViewBuilder
    func dietCard(option: (name:String,icon:String,description:String,color:Color)) -> some View {
        let selected = dietType == option.name
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dietType = option.name
                if option.name == "Fasting" { mealsPerDay = 0 } else if mealsPerDay == 0 { mealsPerDay = 3 }
            }
            UIImpactFeedbackGenerator(style: .light)
                .impactOccurred()
        } label: {
            VStack(spacing: 5) {
                Text(option.icon)
                    .font(.title3)
                Text(option.name)
                    .font(.caption2.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(selected ? option.color.opacity(0.18) : Color(.systemGray6))
            .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(selected ? option.color : Color.clear, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(selected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
    }

    var energySection: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Electricity used")
                        .font(.subheadline.bold())
                    Text("Estimate from your devices & appliances in Kwh")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Button {
                        if electricityKWh >= 1 { electricityKWh = max(0, electricityKWh - 1); UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred() }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(electricityKWh > 0 ? .customBlue : .gray.opacity(0.4)).font(.title3)
                    }
                    .buttonStyle(.plain)
                    TextField("0", value: $electricityKWh, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 56)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline.bold())
                    Button {
                        electricityKWh += 1; UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.customBlue)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }
            Divider()
            Text("Quick references:").font(.caption.bold()).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    energyChip(label: "Phone charge", value: 0.01)
                    energyChip(label: "Laptop (1hr)", value: 0.05)
                    energyChip(label: "TV (1hr)", value: 0.1)
                    energyChip(label: "Washing machine", value: 1.0)
                    energyChip(label: "Dishwasher", value: 1.5)
                    energyChip(label: "Oven (1hr)", value: 2.0)
                }
            }
            infoNote("💡 Average US home uses ~29–30 kWh/day. \n EU averages vary significantly by country ~4–10 . A reliable global household average is not available.")
        }
    }

    @ViewBuilder
    func energyChip(label: String, value: Double) -> some View {
        Button { electricityKWh += value; UIImpactFeedbackGenerator(style: .light)
            .impactOccurred() }
        label: {
            VStack(spacing: 2) {
                Text("+\(String(format: value < 1 ? "%.2f" : "%.1f", value))")
                    .font(.caption.bold())
                    .foregroundColor(.customBlue)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.customBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(Color.customBlue.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Anything unusual today? A long trip, a party, working from home?")
                .font(.caption)
                .foregroundColor(.secondary)
            TextEditor(text: $notes)
                .frame(minHeight: 90)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.pastelPink.opacity(0.8), lineWidth: 1.5))
        }
    }

    var floatingSaveBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                miniStat(label: "Transport", value: transportTotal, color: .customRed)
                Divider().frame(height: 28)
                miniStat(label: "Diet", value: dietTotal, color: .customPurple)
                Divider().frame(height: 28)
                miniStat(label: "Energy", value: energyTotal, color: .customBlue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
                     
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Total today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f kg CO₂", liveTotal))
                        .font(.title3.bold())
                        .foregroundColor(colorForTotal(liveTotal))
                }
                Spacer()
                Button(action: saveEntry) {
                    Text(saveSuccess ? "Saved" : (editingEntry == nil ? "Save" : "Update"))
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(saveSuccess ? Color.blue.opacity(0.5) : Color.blue)
                        .clipShape(Capsule())
                        .shadow(color: Color.blue.opacity(0.5), radius: 8, x: 0, y: 4)
                }
                .disabled(saveSuccess)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    @ViewBuilder func miniStat(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(String(format: "%.1f", value))
                .font(.caption.bold())
                .foregroundColor(color)
        }.frame(maxWidth: .infinity)
    }

    @ViewBuilder func infoNote(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    func colorForTotal(_ total: Double) -> Color {
        switch total {
        case ..<2: return .customGreen
        case 2..<5: return Color(hex:"#52B87F")
        case 5..<10: return .customBlue
        case 10..<20: return .customRed
        default: return .customOrange
        }
    }

    private func saveEntry() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let entry = DailyEntry(
            id: editingEntry?.id ?? UUID(),
            date: editingEntry?.date ?? Date(),
            transportFootprint: transportTotal,
            dietFootprint: dietTotal,
            energyFootprint: energyTotal,
            notes: notes
        )
        if editingEntry != nil { store.updateEntry(entry) } else { store.addEntry(entry) }
        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
        saveSuccess = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            if editingEntry != nil { dismiss() } else { withAnimation { saveSuccess = false }; resetFields() }
        }
    }

    private func resetFields() {
        carDistance=0;
        carIsElectric=false;
        motoDistance=0;
        motoIsElectric=false
        busDistance=0;
        busIsElectric=false;
        trainDistance=0;
        trainIsElectric=false
        taxiDistance=0;
        taxiIsElectric=false;
        planeDistance=0
        metroDistance=0;
        eScooterDistance=0;
        bikeDistance=0
        mealsPerDay=0;
        dietType="";
        electricityKWh=0;
        notes=""
        expandedSection = .diet
    }
}
