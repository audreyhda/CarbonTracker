//
//  DataStore.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class DataStore: ObservableObject {
    private let container: ModelContainer
    private var context: ModelContext

    @Published var entries: [DailyEntry] = []
    @Published var challenges: [Challenge] = []

    private(set) var todayTransport: Double = 0
    private(set) var todayDiet: Double = 0
    private(set) var todayEnergy: Double = 0
    private(set) var todayTotal: Double = 0
    private(set) var avgPerDay: Double = 0
    private(set) var projectedAnnual: Double = 0
    private(set) var streakDays: Int = 0
    private(set) var dailyTotals: [(date: Date, transport: Double, diet: Double, energy: Double, total: Double)] = []
    private(set) var completedChallengeCount: Int = 0
    private(set) var activeChallenges: [Challenge] = []
    private(set) var totalImpactIfCompleted: Double = 0
    private(set) var categoryPoints: [CategoryPoint] = []

    init() {
        let schema = Schema([DailyEntry.self, Challenge.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        context = container.mainContext

        loadEntries()
        loadChallenges()

        if challenges.isEmpty {
            insertDefaultChallenges()
        }
        resetChallengesIfNewDay()
        if entries.isEmpty {
            insertFakeData()
        }
        recompute()
        recomputeChallengeCache()
    }

    // MARK: - Load

    private func loadEntries() {
        let descriptor = FetchDescriptor<DailyEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        entries = (try? context.fetch(descriptor)) ?? []
    }

    private func loadChallenges() {
        let descriptor = FetchDescriptor<Challenge>(sortBy: [SortDescriptor(\.name)])
        challenges = (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Save

    private func save() {
        try? context.save()
    }

    // MARK: - Entries CRUD

    func addEntry(_ entry: DailyEntry) {
        context.insert(entry)
        save()
        entries.insert(entry, at: 0)
        entries.sort { $0.date > $1.date }
        recompute()
    }

    func updateEntry(_ entry: DailyEntry) {
        save()
        entries.sort { $0.date > $1.date }
        recompute()
    }

    func deleteEntry(_ entry: DailyEntry) {
        context.delete(entry)
        save()
        entries.removeAll { $0.id == entry.id }
        recompute()
    }

    // MARK: - Challenge Actions

    func toggleChallenge(_ challenge: Challenge) {
        challenge.isCompleted.toggle()
        if challenge.isCompleted {
            challenge.completionDates.append(Date())
        }
        save()
        recomputeChallengeCache()
    }

    func toggleActive(_ challenge: Challenge) {
        challenge.isActive.toggle()
        if challenge.isActive {
            challenge.activatedDate = dayFormatter.string(from: Date())
        } else {
            challenge.isCompleted = false
            challenge.activatedDate = ""
        }
        save()
        recomputeChallengeCache()
    }

    func completeAllChallenges() {
        for challenge in challenges where challenge.isActive && !challenge.isCompleted {
            challenge.isCompleted = true
            challenge.completionDates.append(Date())
        }
        save()
        recomputeChallengeCache()
    }

    func toggleAllActive(in category: String) {
        let filtered = category == "All" ? challenges : challenges.filter { $0.category == category }
        let allActive = filtered.allSatisfy { $0.isActive }
        let todayString = dayFormatter.string(from: Date())
        for challenge in challenges {
            let matches = category == "All" || challenge.category == category
            if matches {
                if allActive {
                    challenge.isActive = false
                    challenge.isCompleted = false
                    challenge.activatedDate = ""
                } else {
                    challenge.isActive = true
                    challenge.activatedDate = todayString
                }
            }
        }
        save()
        recomputeChallengeCache()
    }

    func isCategoryAllActive(_ category: String) -> Bool {
        let filtered = category == "All" ? challenges : challenges.filter { $0.category == category }
        return !filtered.isEmpty && filtered.allSatisfy { $0.isActive }
    }

    func resetChallengesIfNewDay() {
        let todayString = dayFormatter.string(from: Date())
        var changed = false
        for challenge in challenges {
            if challenge.isActive && challenge.activatedDate != todayString {
                challenge.isActive = false
                challenge.isCompleted = false
                changed = true
            }
        }
        if changed {
            save()
            recomputeChallengeCache()
        }
    }

    // MARK: - Recompute

    private func recompute() {
        let cal = Calendar.current
        let todayEntries = entries.filter { cal.isDateInToday($0.date) }
        todayTransport = todayEntries.reduce(0) { $0 + $1.transportFootprint }
        todayDiet      = todayEntries.reduce(0) { $0 + $1.dietFootprint }
        todayEnergy    = todayEntries.reduce(0) { $0 + $1.energyFootprint }
        todayTotal     = todayTransport + todayDiet + todayEnergy

        var transport: [Date: Double] = [:]
        var diet:      [Date: Double] = [:]
        var energy:    [Date: Double] = [:]
        var total:     [Date: Double] = [:]
        for entry in entries {
            let day = cal.startOfDay(for: entry.date)
            transport[day, default: 0] += entry.transportFootprint
            diet[day,      default: 0] += entry.dietFootprint
            energy[day,    default: 0] += entry.energyFootprint
            total[day,     default: 0] += entry.totalFootprint
        }
        dailyTotals = total.keys.sorted().map { day in
            (date: day,
             transport: transport[day, default: 0],
             diet: diet[day, default: 0],
             energy: energy[day, default: 0],
             total: total[day, default: 0])
        }

        if dailyTotals.isEmpty {
            avgPerDay = 0; projectedAnnual = 0
        } else {
            avgPerDay = dailyTotals.map(\.total).reduce(0, +) / Double(dailyTotals.count)
            projectedAnnual = avgPerDay * 365
        }

        var daysSet: Set<String> = []
        for entry in entries { daysSet.insert(dayFormatter.string(from: entry.date)) }
        var streak = 0
        var startDate = cal.startOfDay(for: Date())
        if !daysSet.contains(dayFormatter.string(from: startDate)),
           let yesterday = cal.date(byAdding: .day, value: -1, to: startDate),
           daysSet.contains(dayFormatter.string(from: yesterday)) {
            startDate = yesterday
        }
        var cursor = startDate
        while daysSet.contains(dayFormatter.string(from: cursor)) {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        streakDays = streak

        categoryPoints = dailyTotals.flatMap { day in [
            CategoryPoint(date: day.date, category: "Transport", value: day.transport),
            CategoryPoint(date: day.date, category: "Diet", value: day.diet),
            CategoryPoint(date: day.date, category: "Energy", value: day.energy),
        ]}
        objectWillChange.send()
    }

    private func recomputeChallengeCache() {
        completedChallengeCount = challenges.filter(\.isCompleted).count
        activeChallenges = challenges.filter { $0.isActive }
        totalImpactIfCompleted  = activeChallenges.reduce(0) { $0 + $1.impactKg }
        objectWillChange.send()
    }

    // MARK: - Default Challenges

    private func insertDefaultChallenges() {
        for c in Self.defaultChallenges {
            context.insert(c)
        }
        save()
        loadChallenges()
    }

    static let defaultChallenges: [Challenge] = [
        // Transport
        Challenge(name: "Car-Free Day",         description: "No car trips — walk, cycle or transit",      icon: "car.side",                            category: "transport", impactKg: -4.8),
        Challenge(name: "Bike to Work",          description: "Swap your commute for a bike ride",          icon: "bicycle",                             category: "transport", impactKg: -3.2),
        Challenge(name: "Public Transit",        description: "Bus or train instead of driving",            icon: "bus.fill",                            category: "transport", impactKg: -2.5),
        Challenge(name: "Walk Short Trips",      description: "Walk every trip under 1 km",                 icon: "figure.walk",                         category: "transport", impactKg: -1.2),
        Challenge(name: "Carpool",               description: "Share your journey with someone",            icon: "person.2.fill",                       category: "transport", impactKg: -2.4),
        Challenge(name: "Train Not Plane",       description: "Choose rail over a short-haul flight",       icon: "tram.fill",                           category: "transport", impactKg: -8.0),
        Challenge(name: "Remote Work Day",       description: "Work from home — no commute",                icon: "house.fill",                          category: "transport", impactKg: -3.5),
        Challenge(name: "Errand Batch Trip",     description: "Combine all errands into one trip",          icon: "map.fill",                            category: "transport", impactKg: -1.8),
        Challenge(name: "No Ride-Hailing",       description: "Avoid Uber/taxi today",                      icon: "car.side.roof.cargo.carrier.slash",   category: "transport", impactKg: -2.0),
        Challenge(name: "Drive Smoothly",        description: "Avoid rapid acceleration & speeding",        icon: "speedometer",                         category: "transport", impactKg: -1.0),
        Challenge(name: "Check Tire Pressure",   description: "Inflate tires to optimal pressure",          icon: "gauge.with.dots.needle.50percent",    category: "transport", impactKg: -0.7),
        Challenge(name: "Metro Day",             description: "Use metro/subway for all trips today",       icon: "tram.fill",                           category: "transport", impactKg: -3.0),
        Challenge(name: "E-Scooter Trip",        description: "Use an e-scooter instead of a car",         icon: "scooter",                             category: "transport", impactKg: -1.6),
        Challenge(name: "Skip the Lift",         description: "Take stairs — every floor counts",           icon: "figure.stairs",                       category: "transport", impactKg: -0.1),
        Challenge(name: "Slow Down on Highway",  description: "Drive at 110 km/h max to cut fuel 15%",     icon: "gauge.low",                           category: "transport", impactKg: -1.4),
        Challenge(name: "Night Train",           description: "Take an overnight train vs. flying",         icon: "moon.stars.fill",                     category: "transport", impactKg: -9.0),
        Challenge(name: "E-Bike Day",            description: "Use an electric bike for all trips",         icon: "bolt.fill",                           category: "transport", impactKg: -2.8),
        Challenge(name: "Light Luggage",         description: "Remove extra weight from your car today",    icon: "bag.badge.minus",                     category: "transport", impactKg: -0.5),
        Challenge(name: "Transit Pass Day",      description: "Use only public transport for all trips",    icon: "ticket.fill",                         category: "transport", impactKg: -3.0),
        // Diet
        Challenge(name: "Meatless Day",          description: "Go fully plant-based today",                 icon: "leaf.fill",                           category: "diet", impactKg: -2.1),
        Challenge(name: "Local Produce",         description: "Buy 3+ locally grown items",                 icon: "storefront",                          category: "diet", impactKg: -0.8),
        Challenge(name: "Zero Food Waste",       description: "Use all leftovers, waste nothing",           icon: "trash.slash",                         category: "diet", impactKg: -0.5),
        Challenge(name: "Vegan Meal",            description: "Cook one fully vegan meal",                  icon: "carrot.fill",                         category: "diet", impactKg: -1.4),
        Challenge(name: "No Beef Today",         description: "Skip beef — choose fish or legumes",         icon: "fork.knife",                          category: "diet", impactKg: -3.3),
        Challenge(name: "Plant Milk",            description: "Switch to oat or almond milk",               icon: "cup.and.saucer",                      category: "diet", impactKg: -0.6),
        Challenge(name: "Vegetarian Day",        description: "No meat or fish today",                      icon: "leaf.circle.fill",                    category: "diet", impactKg: -1.8),
        Challenge(name: "Seasonal Eating",       description: "Choose only seasonal produce",               icon: "calendar",                            category: "diet", impactKg: -0.7),
        Challenge(name: "Bulk Buy",              description: "Buy food with minimal packaging",             icon: "shippingbox.fill",                    category: "diet", impactKg: -0.6),
        Challenge(name: "Low-Carbon Lunch",      description: "Choose legumes over meat at lunch",          icon: "takeoutbag.and.cup.and.straw.fill",   category: "diet", impactKg: -1.5),
        Challenge(name: "No Dairy Day",          description: "Avoid milk, cheese & yogurt today",          icon: "multiply.circle.fill",                category: "diet", impactKg: -1.2),
        Challenge(name: "Grow Something",        description: "Plant herbs or vegetables at home",          icon: "apple.meditate",                      category: "diet", impactKg: -0.4),
        Challenge(name: "Meal Prep Sunday",      description: "Batch-cook 3+ meals to cut food waste",      icon: "refrigerator.fill",                   category: "diet", impactKg: -1.0),
        Challenge(name: "No Food Delivery",      description: "Cook at home instead of ordering in",        icon: "house.and.flag.fill",                 category: "diet", impactKg: -0.9),
        Challenge(name: "Bean Swap",             description: "Replace meat with beans or lentils at dinner", icon: "leaf.arrow.triangle.circlepath",    category: "diet", impactKg: -2.0),
        Challenge(name: "No Plastic Wrap",       description: "Use reusable containers for all food storage", icon: "archivebox.fill",                   category: "diet", impactKg: -0.2),
        Challenge(name: "Whole Grain Day",       description: "Choose wholegrain over refined products",    icon: "circle.grid.2x2.fill",                category: "diet", impactKg: -0.4),
        Challenge(name: "Cook from Scratch",     description: "Make one meal from raw ingredients only",    icon: "frying.pan.fill",                     category: "diet", impactKg: -0.7),
        // Energy
        Challenge(name: "Unplug Devices",        description: "Unplug all standby electronics",             icon: "poweroff",                            category: "energy", impactKg: -0.4),
        Challenge(name: "Short Shower",          description: "Shower under 5 minutes",                     icon: "drop.fill",                           category: "energy", impactKg: -0.6),
        Challenge(name: "Lights Out",            description: "Turn off lights when leaving rooms",          icon: "lightbulb.slash",                     category: "energy", impactKg: -0.2),
        Challenge(name: "Line Dry",              description: "Air dry laundry instead of dryer",            icon: "wind",                                category: "energy", impactKg: -2.4),
        Challenge(name: "Cool Wash",             description: "Wash clothes at 30°C not 60°C",              icon: "washer.fill",                         category: "energy", impactKg: -0.7),
        Challenge(name: "Turn Down Heat",        description: "Lower your thermostat by 1°C",               icon: "thermometer.low",                     category: "energy", impactKg: -0.8),
        Challenge(name: "LED Upgrade",           description: "Replace one bulb with LED",                  icon: "lightbulb.fill",                      category: "energy", impactKg: -0.9),
        Challenge(name: "Power Strip Off",       description: "Turn off power strip overnight",              icon: "switch.2",                            category: "energy", impactKg: -0.3),
        Challenge(name: "Cold Water Rinse",      description: "Use cold water for dishes",                  icon: "drop.circle",                         category: "energy", impactKg: -0.4),
        Challenge(name: "Natural Light Only",    description: "Use daylight instead of lights",              icon: "sun.max.fill",                        category: "energy", impactKg: -0.3),
        Challenge(name: "Fan Instead of AC",     description: "Use a fan instead of air conditioning",      icon: "fan.fill",                            category: "energy", impactKg: -2.2),
        Challenge(name: "Full Load Only",        description: "Run washer/dishwasher fully loaded",          icon: "washer.circle.fill",                  category: "energy", impactKg: -0.5),
        Challenge(name: "No Screen Hour",        description: "Switch off all screens for 1 hour",           icon: "iphone.slash",                        category: "energy", impactKg: -0.1),
        Challenge(name: "Boil Less Water",       description: "Fill kettle only as much as you need",        icon: "flame.fill",                          category: "energy", impactKg: -0.2),
        Challenge(name: "Eco Mode Washing",      description: "Use eco programme on washer/dishwasher",      icon: "leaf.circle",                         category: "energy", impactKg: -0.6),
        Challenge(name: "Seal Drafts",           description: "Block drafts around doors and windows",       icon: "wind.snow",                           category: "energy", impactKg: -1.2),
        Challenge(name: "Solar Charge",          description: "Charge devices from solar panel or power bank", icon: "sun.and.horizon.fill",              category: "energy", impactKg: -0.3),
        Challenge(name: "Cold Shower",           description: "Take a fully cold shower today",              icon: "snowflake",                           category: "energy", impactKg: -0.8),
        // Lifestyle
        Challenge(name: "Reusable Bag",          description: "Bring your own shopping bags",                icon: "bag.fill",                            category: "lifestyle", impactKg: -0.1),
        Challenge(name: "Reusable Bottle",       description: "Carry a refillable water bottle",             icon: "waterbottle.fill",                    category: "lifestyle", impactKg: -0.1),
        Challenge(name: "Compost",               description: "Compost your food scraps today",              icon: "arrow.3.trianglepath",                category: "lifestyle", impactKg: -0.3),
        Challenge(name: "Second-Hand Buy",       description: "Buy something second-hand instead",           icon: "tag.fill",                            category: "lifestyle", impactKg: -1.5),
        Challenge(name: "Repair Item",           description: "Fix something instead of replacing it",       icon: "wrench.and.screwdriver.fill",          category: "lifestyle", impactKg: -2.0),
        Challenge(name: "No Fast Fashion",       description: "Skip buying new clothing today",              icon: "tshirt.fill",                         category: "lifestyle", impactKg: -2.5),
        Challenge(name: "Digital Receipt",       description: "Choose digital over printed receipt",         icon: "doc.text.fill",                       category: "lifestyle", impactKg: -0.05),
        Challenge(name: "Library Visit",         description: "Borrow instead of buying a book",             icon: "books.vertical.fill",                 category: "lifestyle", impactKg: -1.1),
        Challenge(name: "Plastic-Free Day",      description: "Avoid single-use plastics entirely",          icon: "nosign",                              category: "lifestyle", impactKg: -0.4),
        Challenge(name: "Eco Cleaning",          description: "Use eco-friendly cleaning products",          icon: "sparkles",                            category: "lifestyle", impactKg: -0.3),
        Challenge(name: "Digital Declutter",     description: "Delete unused apps & emails to cut server load", icon: "trash.fill",                       category: "lifestyle", impactKg: -0.1),
        Challenge(name: "Swap Gift Wrap",        description: "Use newspaper or fabric to wrap a gift",      icon: "gift.fill",                           category: "lifestyle", impactKg: -0.2),
        Challenge(name: "Donate Clothes",        description: "Drop off clothes to charity instead of binning", icon: "heart.fill",                       category: "lifestyle", impactKg: -1.8),
        Challenge(name: "Plant a Seed",          description: "Start growing something at home today",       icon: "leaf.fill",                           category: "lifestyle", impactKg: -0.5),
        Challenge(name: "Swap to Bar Soap",      description: "Use bar soap instead of liquid (less plastic)", icon: "drop.fill",                         category: "lifestyle", impactKg: -0.2),
        Challenge(name: "No Amazon Day",         description: "Avoid online fast delivery for 24 hrs",       icon: "shippingbox.fill",                    category: "lifestyle", impactKg: -0.8),
        Challenge(name: "Beeswax Wrap",          description: "Use reusable beeswax wrap instead of cling film", icon: "seal.fill",                       category: "lifestyle", impactKg: -0.15),
        Challenge(name: "Refill a Product",      description: "Refill soap, shampoo or cleaning product",   icon: "arrow.circlepath",                    category: "lifestyle", impactKg: -0.3),
    ]

    // MARK: - Fake Data (first launch only)

    private func insertFakeData() {
        let calendar = Calendar.current
        let dietTypes = ["Meat\u{2011}heavy","Average","Pescatarian","Vegetarian","Vegan", "Average","Meat\u{2011}heavy","Pescatarian","Vegetarian","Vegan"]
        let transports: [(car:Double,bus:Double,train:Double,plane:Double)] = [
            (12,0,0,0),(0,8,0,0),(5,0,15,0),(0,0,0,0),(20,0,0,0),
            (0,10,0,0),(8,0,0,0),(0,0,20,0),(15,5,0,0),(0,0,30,0)
        ]
        let energyValues: [Double] = [8,5,12,6,9,4,11,7,10,6]
        for i in 1...10 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let t = transports[i-1]
            let transportFootprint = FootprintCalculator.calculateTransport(
                carMiles: t.car, carIsElectric: false,
                motoMiles: 0, motoIsElectric: false,
                busMiles: t.bus, busIsElectric: false,
                trainMiles: t.train, trainIsElectric: false,
                taxiMiles: 0, taxiIsElectric: false,
                planeMiles: t.plane,
                metroMiles: 0, eScooterMiles: 0, bikeMiles: 0)
            let dietFootprint  = FootprintCalculator.calculateDiet(mealsPerDay: 3, dietType: dietTypes[i-1])
            let energyFootprint = FootprintCalculator.calculateEnergy(electricityKWh: energyValues[i-1])
            let note = i == 10 ? "Long-haul flight" : i == 4 ? "WFH day" : ""
            let entry = DailyEntry(date: date,
                                   transportFootprint: transportFootprint,
                                   dietFootprint: dietFootprint,
                                   energyFootprint: energyFootprint,
                                   notes: note)
            context.insert(entry)
            entries.append(entry)
        }
        save()
        entries.sort { $0.date > $1.date }
    }
}
