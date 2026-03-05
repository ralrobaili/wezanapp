//
//  Stores.swift
//  wezanapp
//
//  Created by raghad alenezi on 16/09/1447 AH.
//
import Foundation
import Combine

// MARK: – Dose Store
final class DoseStore: ObservableObject {
    @Published private(set) var doses: [DoseRecord] = []
    private let key = "wezan.v2.doses"

    init() { load() }

    func add(_ d: DoseRecord)    { doses.insert(d, at: 0); save() }
    func delete(_ d: DoseRecord) { doses.removeAll { $0.id == d.id }; save() }

    func doses(from: Date, to: Date) -> [DoseRecord] {
        doses.filter { $0.timestamp >= from && $0.timestamp <= to }
    }
    func doses(on date: Date) -> [DoseRecord] {
        let cal = Calendar.current
        return doses.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
    }
    func totalUnits(on date: Date) -> Double {
        doses(on: date).reduce(0) { $0 + $1.units }
    }
    var activeDoses: [DoseRecord] { doses.filter(\.isActive) }

    // Group by localised Arabic day string
    var groupedByDay: [(key: String, doses: [DoseRecord])] {
        let f = DateFormatter(); f.locale = Locale(identifier: "ar_SA"); f.dateFormat = "EEEE، d MMMM"
        var dict = [String: [DoseRecord]]()
        var order = [String]()
        for d in doses {
            let k = f.string(from: d.timestamp)
            if dict[k] == nil { order.append(k) }
            dict[k, default: []].append(d)
        }
        return order.map { (key: $0, doses: dict[$0]!) }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(doses) { UserDefaults.standard.set(data, forKey: key) }
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([DoseRecord].self, from: data) else {
            doses = []; return
        }
        doses = saved
    }
}

// MARK: – Settings Store
final class SettingsStore: ObservableObject {
    @Published var glucoseUnit: GlucoseUnit {
        didSet { UserDefaults.standard.set(glucoseUnit.rawValue, forKey: "wUnit") }
    }
    @Published var targetLow: Double {
        didSet { UserDefaults.standard.set(targetLow,  forKey: "wLow") }
    }
    @Published var targetHigh: Double {
        didSet { UserDefaults.standard.set(targetHigh, forKey: "wHigh") }
    }
    @Published var hasOnboarded: Bool {
        didSet { UserDefaults.standard.set(hasOnboarded, forKey: "wOnboarded") }
    }

    init() {
        let u  = UserDefaults.standard
        glucoseUnit  = GlucoseUnit(rawValue: u.string(forKey: "wUnit") ?? "") ?? .mgdL
        targetLow    = u.double(forKey: "wLow") .ifZero(70)
        targetHigh   = u.double(forKey: "wHigh").ifZero(180)
        hasOnboarded = u.bool(forKey: "wOnboarded")
    }
}

extension Double { func ifZero(_ f: Double) -> Double { self == 0 ? f : self } }
