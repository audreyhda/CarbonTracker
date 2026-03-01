//
//  FootPrintCalculator.swift
//  SwiftStudentChallenge2026
//
//  Created by Audrey Huillard D'Aignaux on 01/03/26.
//

import Foundation
import SwiftUI

struct FootprintCalculator {
    static let carGasPerMile = 0.404;
    static let carElectricPerMile = 0.2
    static let motoGasPerMile = 0.2;
    static let motoElectricPerMile = 0.1
    static let busGasPerMile = 0.14;
    static let busElectricPerMile = 0.08
    static let trainGasPerMile = 0.06;
    static let trainElectricPerMile = 0.04
    static let taxiGasPerMile = 0.404;
    static let taxiElectricPerMile = 0.2
    static let planePerMile = 0.5
    static let metroPerMile = 0.005
    static let eScooterPerMile = 0.065
    static let bikePerMile = 0.013
    static let electricityPerKWh = 0.4

    static let dietFactors: [String: Double] = [
        "Meat‑heavy": 3.3,
        "Average": 2.5,
        "Pescatarian": 1.9,
        "Vegetarian": 1.7,
        "Vegan": 1.2,
        "Fasting": 0.0,
    ]

    static func calculateTransport(
        carMiles: Double,
        carIsElectric: Bool,
        motoMiles: Double,
        motoIsElectric: Bool,
        busMiles: Double,
        busIsElectric: Bool,
        trainMiles: Double,
        trainIsElectric: Bool,
        taxiMiles: Double,
        taxiIsElectric: Bool,
        planeMiles: Double,
        metroMiles: Double,
        eScooterMiles: Double,
        bikeMiles: Double) -> Double {
        carMiles * (carIsElectric ? carElectricPerMile : carGasPerMile) +
        motoMiles * (motoIsElectric ? motoElectricPerMile : motoGasPerMile) +
        busMiles * (busIsElectric ? busElectricPerMile : busGasPerMile) +
        trainMiles * (trainIsElectric ? trainElectricPerMile : trainGasPerMile) +
        taxiMiles * (taxiIsElectric ? taxiElectricPerMile : taxiGasPerMile) +
        planeMiles * planePerMile +
        metroMiles * metroPerMile +
        eScooterMiles * eScooterPerMile +
        bikeMiles * bikePerMile
    }

    static func calculateDiet(mealsPerDay: Double, dietType: String) -> Double {
        guard !dietType.isEmpty else { return 0 }
        return (dietFactors[dietType] ?? 0) * mealsPerDay
    }
    static func calculateEnergy(electricityKWh: Double) -> Double { electricityKWh * electricityPerKWh }
}
