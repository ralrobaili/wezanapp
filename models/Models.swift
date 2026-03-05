//
//  Models.swift
//  wezanapp
//
//  Created by raghad alenezi on 16/09/1447 AH.
//

import Foundation
import SwiftUI

// MARK: – Glucose Unit
enum GlucoseUnit: String, Codable, CaseIterable {
    case mgdL  = "mg/dL"
    case mmolL = "mmol/L"
    var label: String { rawValue }
    var decimals: Int { self == .mmolL ? 1 : 0 }
    func display(_ mgdL: Double) -> Double {
        self == .mgdL ? mgdL : mgdL / 18.015
    }
    func displayString(_ mgdL: Double) -> String {
        let v = display(mgdL)
        return self == .mgdL ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }
}

// MARK: – Glucose Status
enum GlucoseStatus {
    case low, normal, high
    init(mgdL: Double) {
        if mgdL < 70 { self = .low } else if mgdL > 180 { self = .high } else { self = .normal }
    }
    var label: String {
        switch self { case .low: "منخفض" ; case .normal: "ضمن النطاق" ; case .high: "مرتفع" }
    }
    var color: Color {
        switch self { case .low: .wLow ; case .normal: .wNormal ; case .high: .wHigh }
    }
    var sfSymbol: String {
        switch self { case .low: "arrow.down.circle.fill" ; case .normal: "checkmark.circle.fill" ; case .high: "arrow.up.circle.fill" }
    }
    var chipBg: Color { color.opacity(0.15) }
}

// MARK: – Glucose Reading
struct GlucoseReading: Identifiable, Equatable {
    let id        : UUID   = UUID()
    let valueMgdL : Double
    let timestamp : Date
    let source    : String
    var status: GlucoseStatus { GlucoseStatus(mgdL: valueMgdL) }
    func display(_ unit: GlucoseUnit) -> String { unit.displayString(valueMgdL) }
}

// MARK: – Insulin Type
enum InsulinType: String, Codable, CaseIterable, Identifiable {
    case rapid  = "سريع المفعول"
    case long   = "طويل المفعول"
    case mixed  = "مختلط"
    var id: String { rawValue }
    var durationH: Double { switch self { case .rapid: 4; case .long: 24; case .mixed: 12 } }
    var sfSymbol: String {
        switch self { case .rapid: "bolt.fill"; case .long: "moon.fill"; case .mixed: "capsule.fill" }
    }
    var color: Color {
        switch self { case .rapid: .wPrimary; case .long: .wBlue; case .mixed: .wAccent }
    }
}

// MARK: – Dose Record
struct DoseRecord: Identifiable, Codable, Equatable {
    var id            : UUID         = UUID()
    var units         : Double
    var insulinType   : InsulinType
    var timestamp     : Date
    var note          : String       = ""
    var injectionSite : String       = ""
    var glucoseAtDose : Double?

    var isActive: Bool {
        Date().timeIntervalSince(timestamp) / 3600 < insulinType.durationH
    }
    var progressFraction: Double {
        min(Date().timeIntervalSince(timestamp) / 3600 / insulinType.durationH, 1)
    }
    var remainingHours: Double {
        max(0, insulinType.durationH - Date().timeIntervalSince(timestamp) / 3600)
    }
}

// MARK: – Export Range
enum ExportRange: String, CaseIterable, Identifiable {
    case month       = "آخر شهر"
    case threeMonths = "آخر 3 شهور"
    case sixMonths   = "آخر 6 شهور"
    var id: String { rawValue }
    var startDate: Date {
        let c = Calendar.current
        switch self {
        case .month:       return c.date(byAdding: .month, value: -1, to: .now)!
        case .threeMonths: return c.date(byAdding: .month, value: -3, to: .now)!
        case .sixMonths:   return c.date(byAdding: .month, value: -6, to: .now)!
        }
    }
}

// MARK: – Seed data
extension DoseRecord {
    static var preview: [DoseRecord] {
        let n = Date()
        return [
            .init(units: 8,  insulinType: .rapid, timestamp: n.addingTimeInterval(-2*3600),  note: "قبل الإفطار",    glucoseAtDose: 145),
            .init(units: 4,  insulinType: .rapid, timestamp: n.addingTimeInterval(-6*3600),  note: "قبل الغداء",     glucoseAtDose: 132),
            .init(units: 20, insulinType: .long,  timestamp: n.addingTimeInterval(-14*3600), note: "جرعة ليلية",     glucoseAtDose: 118),
            .init(units: 6,  insulinType: .rapid, timestamp: n.addingTimeInterval(-30*3600), note: "قبل العشاء",     glucoseAtDose: 160),
            .init(units: 20, insulinType: .long,  timestamp: n.addingTimeInterval(-38*3600), note: "جرعة ليلية",     glucoseAtDose: 110),
            .init(units: 7,  insulinType: .rapid, timestamp: n.addingTimeInterval(-54*3600), note: "وجبة خفيفة",     glucoseAtDose: 155),
            .init(units: 5,  insulinType: .rapid, timestamp: n.addingTimeInterval(-78*3600), note: "قبل الإفطار",    glucoseAtDose: 128),
            .init(units: 20, insulinType: .long,  timestamp: n.addingTimeInterval(-86*3600), note: "جرعة ليلية",     glucoseAtDose: 114),
        ]
    }
}
