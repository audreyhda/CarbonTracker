//
//  TipsCoach.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif
import Combine

@MainActor
class TipsCoach: ObservableObject {
    @Published var advice: String = ""
    @Published var isLoading: Bool = false
    @Published var usingAI: Bool = false

#if canImport(FoundationModels)
    @available(iOS 26, *)
    private lazy var session = LanguageModelSession()
#endif

    static let transportTips: [String] = [
        "Transport is your top emission source. Combining errands into one trip or carpooling once a week can cut your footprint by up to 20%.",
        "Even one car-free day per week adds up fast. Walking or cycling trips under 3 km saves roughly 0.4 kg CO₂ each time.",
        "Public transit is 4–10× more efficient than a solo car trip. Swapping one commute per week could save over 50 kg CO₂ a month.",
        "Smooth acceleration and avoiding idling can reduce fuel use by 15%. EVs cut per-mile emissions by more than half.",
        "Short-haul flights are the most carbon-intensive trips you can take. Replacing one flight with a train saves 80–90% of the emissions for the same route.",
        "Carpooling with just one other person halves your transport footprint instantly. Ride-share apps make it easier than ever.",
        "Working from home two days a week can cut commute emissions by 40%. If remote work is an option, it's one of the highest-impact changes you can make.",
        "Keeping your car's tyres properly inflated improves fuel efficiency by up to 3%. A 5-minute check that saves money and CO₂.",
        "Trains emit on average 80% less CO₂ per passenger than planes on equivalent routes. For distances under 700 km, rail is almost always the greener choice.",
        "Choosing an electric or hybrid taxi option typically cuts transport emissions by 50–70% compared to a standard petrol ride.",
        "Cycling instead of driving for a 5 km round trip saves roughly 1 kg CO₂. Do that twice a week and you've saved over 100 kg by year end.",
        "If you must fly, choosing direct routes avoids the extra emissions of layovers and reduces contrail warming effects at altitude.",
        "Cold engines use significantly more fuel. Combining short trips into one longer journey can reduce fuel consumption by up to 25% compared to multiple cold starts.",
        "Driving at 110 km/h instead of 130 km/h can cut fuel use and emissions by roughly 15–20% on highways.",
        "Removing roof racks or cargo boxes when not in use improves aerodynamics and can reduce fuel consumption by up to 10% at motorway speeds.",
        "Every extra 50 kg carried in your car increases fuel consumption by about 1–2%. Clearing unnecessary weight makes a measurable difference over time.",
        "Electric vehicles typically emit 50–70% less CO₂ over their lifetime compared to petrol cars — even when accounting for battery production.",
        "For trips under 2 km, walking is often faster door-to-door than driving — and produces zero emissions.",
        "Switching one weekly car commute to cycling can save roughly 150–200 kg CO₂ per year depending on distance.",
        "High-speed rail powered by renewable electricity can reduce emissions by over 90% compared to flying the same route.",
        "Car-sharing services reduce the number of vehicles on the road and can lower personal transport emissions by 20–40% for urban users.",
        "Proper route planning to avoid congestion reduces idling time, which can account for up to 10% of urban driving emissions.",
        "E-bikes are one of the most efficient forms of motorised transport, using around 100× less energy per km than a petrol car.",
        "Switching to a monthly public transit pass tends to increase transit use by 30% — commitment nudges greener habits.",
        "Taking a night train instead of a short-haul flight eliminates the hotel stay emissions too, making it doubly green.",
        "Metro and subway systems are among the lowest-emission urban transport options, producing roughly 4–6 g CO₂ per passenger-km.",
        "Replacing a 10 km car commute with the metro can save around 300–400 g CO₂ per trip — nearly 100 kg per year for daily commuters.",
        "Electric scooters produce about 25–60 g CO₂ per km when accounting for battery charging — still far less than a petrol car.",
        "A regular bicycle produces near-zero direct emissions. Even accounting for food energy, it emits around 10–15 g CO₂ per km — one of the greenest options available.",
        "Combining metro with a short bike or scooter leg for the first/last mile is one of the most efficient urban commute patterns.",
    ]

    static let dietTips: [String] = [
        "Diet is your biggest impact right now. Replacing one meat meal with a plant-based option saves up to 0.8 kg CO₂ — that's nearly 300 kg over a year.",
        "Beef produces roughly 20× more emissions per gram of protein than tofu. Even swapping beef for chicken cuts diet emissions by around 50% per meal.",
        "Buying local and seasonal produce reduces food transport emissions and supports nearby farmers. A weekly market visit is one of the most impactful food habits you can build.",
        "Food waste accounts for about 8% of global greenhouse gas emissions. Planning meals for the week and using leftovers creatively is one of the easiest wins.",
        "Oat milk produces around 3× fewer emissions than cow's milk and uses 60% less land. Swapping your daily coffee milk alone saves roughly 30 kg CO₂ a year.",
        "A pescatarian diet produces roughly 40% less CO₂ than a meat-heavy one. Fish two or three times a week is a practical middle ground.",
        "Legumes like lentils, chickpeas, and beans are among the most climate-friendly protein sources — producing around 50× less CO₂ than beef per gram of protein.",
        "Ultra-processed foods often have a larger carbon footprint due to energy-intensive manufacturing. Cooking from whole ingredients is better for the planet and for you.",
        "Eating lower on the food chain — more grains, vegetables, and legumes — is consistently identified as one of the top individual actions for climate impact.",
        "Freezing food before it goes off is just as climate-friendly as using it fresh, and dramatically cuts the emissions from wasted food.",
        "Growing even a small pot of herbs or salad leaves eliminates packaging, transport, and refrigeration emissions for those items.",
        "Choosing organic when possible supports soil health, which sequesters more carbon over time — though the biggest gains still come from eating less meat overall.",
        "Producing 1 kg of beef emits roughly 60 kg CO₂e, while 1 kg of lentils emits under 1 kg CO₂e — one of the largest food footprint gaps.",
        "Cheese has one of the highest carbon footprints among dairy products due to the large volume of milk required for production.",
        "Chicken produces about 6× less CO₂ per gram of protein than beef, making it a significantly lower-impact swap if fully plant-based isn't realistic.",
        "Transport typically accounts for less than 10% of most food emissions — what you eat usually matters more than how far it travelled.",
        "Plant-based diets can reduce food-related emissions by up to 50% compared to meat-heavy diets in high-income countries.",
        "Reducing portion sizes of high-impact foods like beef and cheese lowers emissions without requiring a full dietary change.",
        "Buying loose fruits and vegetables instead of heavily packaged options reduces both plastic waste and embedded production emissions.",
        "Home cooking generally produces fewer emissions than restaurant dining due to portion control and reduced food waste.",
        "Globally, about one-third of food produced is wasted. Preventing that waste avoids all the emissions used to grow, transport, and refrigerate it.",
        "Switching from a beef burger to a bean burger once a week saves about 1 kg CO₂ — small change, meaningful habit.",
        "Eating a Mediterranean-style diet (mostly plants, some fish and dairy) cuts food emissions by roughly 30% vs. a standard Western diet.",
        "Meal prepping on weekends reduces impulse food purchases and waste, saving both money and CO₂ over the week.",
        "Fermented foods like kimchi, miso, and tempeh are low-emission, nutrient-dense alternatives to animal proteins.",
    ]

    static let energyTips: [String] = [
        "Energy is your biggest impact area today. Turning off devices at the plug — not just standby — saves around 10% of home electricity with zero effort.",
        "Dropping your thermostat by just 1°C cuts heating emissions by about 8%. Over a full winter, that's a meaningful difference with almost no comfort trade-off.",
        "LED bulbs use 75% less energy than incandescent ones and last 25× longer. Replacing 5 bulbs saves around 40 kg CO₂ per year.",
        "Running your washing machine at 30°C instead of 60°C uses 40% less electricity — with no meaningful difference in cleaning performance for everyday laundry.",
        "Air-drying clothes instead of using a tumble dryer saves 2–3 kg CO₂ per load. In summer it also keeps your home cooler.",
        "Cutting your daily shower by just 5 minutes saves around 15 kg CO₂ per month if you have an electric water heater — plus it reduces water use significantly.",
        "A full fridge is more efficient than a half-empty one — food acts as thermal mass. Keep it reasonably full and defrost the freezer regularly.",
        "Smart power strips automatically cut power to devices in standby. They can reduce idle power consumption by up to 10% without any behaviour change on your part.",
        "Insulating your hot water pipes — a simple DIY job — reduces heat loss and can cut water-heating energy use by around 9%.",
        "Closing doors and using programmable thermostats or room-by-room heating means you only heat the spaces you're actually in.",
        "Solar panels on a typical home generate enough electricity to cut CO₂ emissions by 1–2 tonnes per year. If you rent, many programmes now support tenant-installed systems.",
        "Boiling only as much water as you need saves around 0.5 kg CO₂ per week if you're a frequent tea or coffee drinker — a tiny habit that adds up.",
        "Heating accounts for around 60% of household energy use in many colder countries — making thermostat adjustments one of the highest-impact actions.",
        "Sealing drafts around doors and windows can reduce heating energy use by 10–20% in poorly insulated homes.",
        "Switching to a renewable electricity tariff can reduce your home electricity emissions to near zero depending on the grid mix.",
        "Induction cooktops are around 10% more energy-efficient than conventional electric hobs and significantly more efficient than gas.",
        "Lowering your water heater temperature to 49–55°C reduces standby heat loss and cuts water heating emissions safely.",
        "Dishwashers are typically more water- and energy-efficient than handwashing when run full on eco mode.",
        "Ceiling fans use about 1% of the electricity of air conditioning units, making them one of the most efficient cooling options.",
        "Smart thermostats can reduce heating and cooling emissions by 10–15% through automated scheduling.",
        "Upgrading to an A-rated energy appliance can cut electricity use by 30–50% compared to older models.",
        "Home insulation improvements can reduce total heating emissions by 20–40%, making them one of the highest long-term impact investments.",
        "Charging devices overnight on a timer can shift demand to off-peak hours when the grid often runs on more renewables.",
        "Unplugging your TV's cable or satellite box when not in use saves up to 15–20W constantly — about 130 kWh and 50 kg CO₂ per year.",
        "A programmable hot water timer means your boiler only heats water when you actually need it, cutting standby losses by up to 20%.",
    ]

    static var allTips: String {
        let transportSample = transportTips.prefix(8).enumerated().map {
            "T\($0.offset+1): \($0.element)"
        }.joined(separator: "\n")
        let dietSample = dietTips.prefix(8).enumerated().map {
            "D\($0.offset+1): \($0.element)"
        }.joined(separator: "\n")
        let energySample = energyTips.prefix(8).enumerated().map {
            "E\($0.offset+1): \($0.element)"
        }.joined(separator: "\n")
        return "TRANSPORT TIPS:\n\(transportSample)\n\nDIET TIPS:\n\(dietSample)\n\nENERGY TIPS:\n\(energySample)"
    }

    private var lastTransportIndex: Int = -1
    private var lastDietIndex: Int = -1
    private var lastEnergyIndex: Int = -1

    func generateAdvice(for entries: [DailyEntry], force: Bool = false) async {
        guard advice.isEmpty || force else { return }
        isLoading = true

        let lastSeven = Array(entries.prefix(7))
        let avgTransport = lastSeven.isEmpty ? 0 : lastSeven.map(\.transportFootprint).reduce(0, +) / Double(lastSeven.count)
        let avgDiet = lastSeven.isEmpty ? 0 : lastSeven.map(\.dietFootprint).reduce(0, +) / Double(lastSeven.count)
        let avgEnergy = lastSeven.isEmpty ? 0 : lastSeven.map(\.energyFootprint).reduce(0, +) / Double(lastSeven.count)

        let ranked: [(category: String, avg: Double)] = [
            ("transport", avgTransport),
            ("diet",      avgDiet),
            ("energy",    avgEnergy),
        ].sorted { $0.avg > $1.avg }

        let random = Double.random(in: 0..<1)
        let topCategory: String
        if random < 0.70 {
            topCategory = ranked[0].category
        } else if random < 0.90 {
            topCategory = ranked[1].category
        } else {
            topCategory = ranked[2].category
        }

#if canImport(FoundationModels)
        if #available(iOS 26, *) {
            do {
                usingAI = true
                let prompt = """
                    You are a concise eco-coach. Below are example evidence-based eco tips organised by category. Use them as inspiration for the style, tone, and level of specificity you should aim for.

                    \(TipsCoach.allTips)

                    The user's 7-day averages: transport \(String(format: "%.1f", avgTransport)) kg/day, diet \(String(format: "%.1f", avgDiet)) kg/day, energy \(String(format: "%.1f", avgEnergy)) kg/day.
                    Today's focus category: \(topCategory).

                    Give ONE fresh, practical, specific, evidence-based tip (2–3 sentences max) focused on \(topCategory). Make it slightly different from the example tips above — add a new angle or data point. Be encouraging, not preachy. No bullet points. No intro like "Here's a tip:".
                    """
                let response = try await session.respond(to: prompt)
                advice = response.content
                isLoading = false
                return
            } catch {
                usingAI = false
            }
        }
#endif

        if force { try? await Task.sleep(nanoseconds: 200_000_000) }
        usingAI = false

        func pickIndex(from pool: [String], last: inout Int) -> Int {
            var idx: Int
            repeat {
                idx = Int.random(in: 0..<pool.count)
            } while pool.count > 1 && idx == last
            last = idx
            return idx
        }

        switch topCategory {
        case "transport":
            advice = TipsCoach.transportTips[pickIndex(from: TipsCoach.transportTips, last: &lastTransportIndex)]
        case "diet":
            advice = TipsCoach.dietTips[pickIndex(from: TipsCoach.dietTips, last: &lastDietIndex)]
        default:
            advice = TipsCoach.energyTips[pickIndex(from: TipsCoach.energyTips, last: &lastEnergyIndex)]
        }

        isLoading = false
    }

    func generateAdviceOnLaunch(for entries: [DailyEntry]) async {
        guard advice.isEmpty else { return }
        if entries.isEmpty {
            isLoading = true
            let allTips = TipsCoach.transportTips + TipsCoach.dietTips + TipsCoach.energyTips
            advice = allTips.randomElement() ?? TipsCoach.energyTips[0]
            isLoading = false
            return
        }
        await generateAdvice(for: entries)
    }
}
