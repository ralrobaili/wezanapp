//
//  HealthKitService.swift
//  wezanapp
//
//  Created by raghad alenezi on 16/09/1447 AH.
//

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitService: ObservableObject {

    @Published var authStatus    : HKAuthorizationStatus = .notDetermined
    @Published var latestReading : GlucoseReading?
    @Published var readings      : [GlucoseReading] = []
    @Published var isLoading     : Bool = false

    private let store       = HKHealthStore()
    private let glucoseType = HKQuantityType(.bloodGlucose)
    private var bgTask      : Task<Void, Never>?

    var isAuthorized: Bool { authStatus == .sharingAuthorized }
    var statusLabel : String {
        switch authStatus {
        case .sharingAuthorized: return "متصل"
        case .sharingDenied    : return "مرفوض"
        default                : return "غير مُفعَّل"
        }
    }

    // MARK: – Auth
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await store.requestAuthorization(
                toShare: [glucoseType],
                read   : [glucoseType]
            )
            authStatus = store.authorizationStatus(for: glucoseType)
            if isAuthorized { await startMonitoring() }
        } catch {}
    }

    func checkAuthStatus() {
        authStatus = store.authorizationStatus(for: glucoseType)
    }

    // MARK: – Monitor
    func startMonitoring() async {
        await fetchLatest()
        await fetchReadings(hours: 6)
        // Observer query for real-time updates
        let descriptor = HKQueryDescriptor(sampleType: glucoseType, predicate: nil)
        let updateQ = HKObserverQuery(queryDescriptors: [descriptor]) { [weak self] _, _, _,_  in
            Task { [weak self] in
                await self?.fetchLatest()
                await self?.fetchReadings(hours: 6)
            }
        }
        store.execute(updateQ)
    }

    // MARK: – Fetch latest
    func fetchLatest() async {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let q = HKSampleQuery(sampleType: glucoseType, predicate: nil, limit: 1, sortDescriptors: [sort]) { [weak self] _, s, _ in
            guard let sample = s?.first as? HKQuantitySample else { return }
            let r = GlucoseReading(
                valueMgdL : sample.quantity.doubleValue(for: .gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))),
                timestamp : sample.startDate,
                source    : sample.sourceRevision.source.name
            )
            Task { @MainActor [weak self] in self?.latestReading = r }
        }
        store.execute(q)
    }

    // MARK: – Fetch range
    func fetchReadings(hours: Double) async {
        isLoading = true
        let pred = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-hours * 3600), end: .now, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let q = HKSampleQuery(sampleType: glucoseType, predicate: pred, limit: 500, sortDescriptors: [sort]) { [weak self] _, s, _ in
            let results = (s as? [HKQuantitySample] ?? []).map {
                GlucoseReading(
                    valueMgdL : $0.quantity.doubleValue(for: .gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))),
                    timestamp : $0.startDate,
                    source    : $0.sourceRevision.source.name
                )
            }
            Task { @MainActor [weak self] in
                self?.readings  = results
                self?.isLoading = false
            }
        }
        store.execute(q)
    }

    // MARK: – Export fetch
    func fetchReadings(from start: Date, to end: Date) async -> [GlucoseReading] {
        await withCheckedContinuation { cont in
            let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let q = HKSampleQuery(sampleType: glucoseType, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, s, _ in
                cont.resume(returning: (s as? [HKQuantitySample] ?? []).map {
                    GlucoseReading(
                        valueMgdL : $0.quantity.doubleValue(for: .gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))),
                        timestamp : $0.startDate,
                        source    : $0.sourceRevision.source.name
                    )
                })
            }
            store.execute(q)
        }
    }
}
