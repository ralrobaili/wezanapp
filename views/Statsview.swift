//
//  Stats.swift
//  wezanapp
//
//  Created by raghad alenezi on 16/09/1447 AH.
//
import SwiftUI

struct StatsView: View {
    @EnvironmentObject var health  : HealthKitService
    @EnvironmentObject var doses   : DoseStore
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {

                    // ── 4-stat grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statCard("متوسط السكر",     value: avgGlucose,     unit: settings.glucoseUnit.label, color: .wPrimary,  icon: "waveform.path.ecg")
                        statCard("وقت في النطاق",   value: timeInRange,    unit: "من الوقت",                color: .wNormal,   icon: "target")
                        statCard("وحدات هذا الأسبوع", value: weeklyUnits,  unit: "وحدة",                   color: .wAccent,   icon: "syringe")
                        statCard("إجمالي الجرعات",  value: "\(doses.doses.count)", unit: "جرعة",           color: .wBlue,     icon: "list.bullet.clipboard")
                    }

                    // ── Weekly chart
                    WCard(padding: 20, bg: .wCard) {
                        VStack(alignment: .trailing, spacing: 14) {
                            HStack {
                                Text("آخر 7 أيام")
                                    .font(.wCaption).foregroundColor(.wLabelSec)
                                Spacer()
                                Text("مخطط السكر في الدم")
                                    .font(.wCardTitle).foregroundColor(.wLabel)
                            }
                            if health.readings.count >= 2 {
                                GlucoseSparkline(
                                    readings  : health.readings,
                                    unit      : settings.glucoseUnit,
                                    targetLow : settings.targetLow,
                                    targetHigh: settings.targetHigh,
                                    height    : 120
                                )
                            } else {
                                Text("لا توجد بيانات").font(.wCaption).foregroundColor(.wLabelSec)
                                    .frame(maxWidth: .infinity).padding(.vertical, 40)
                            }
                        }
                    }
                    .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)

                    // ── Insulin breakdown
                    WCard(padding: 20, bg: .wCard) {
                        VStack(alignment: .trailing, spacing: 14) {
                            Text("توزيع نوع الإنسولين")
                                .font(.wCardTitle).foregroundColor(.wLabel)
                                .frame(maxWidth: .infinity, alignment: .trailing)

                            ForEach(InsulinType.allCases) { t in
                                let cnt   = doses.doses.filter { $0.insulinType == t }.count
                                let total = max(doses.doses.count, 1)
                                let frac  = Double(cnt) / Double(total)
                                HStack(spacing: 10) {
                                    Image(systemName: t.sfSymbol)
                                        .foregroundColor(t.color)
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(width: 22)
                                    Text(t.rawValue)
                                        .font(.wBody).foregroundColor(.wLabel)
                                    Spacer()
                                    GeometryReader { g in
                                        ZStack(alignment: .trailing) {
                                            Capsule().fill(Color.wTint1).frame(height: 6)
                                            Capsule().fill(t.color).frame(width: g.size.width * frac, height: 6)
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                        }
                                    }
                                    .frame(width: 100, height: 6)
                                    Text("\(cnt)")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(t.color)
                                        .frame(width: 24, alignment: .trailing)
                                }
                            }
                        }
                    }
                    .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)

                    Spacer(minLength: 90)
                }
                .padding(.horizontal, WSpacing.lg)
                .padding(.top, 8)
            }
            .background(Color.wBg.ignoresSafeArea())
            .navigationTitle("الإحصائيات")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { Task { await health.fetchReadings(hours: 168) } }
        }
    }

    // MARK: – Stat Card
    private func statCard(_ title: String, value: String, unit: String, color: Color, icon: String) -> some View {
        WCard(padding: 16, bg: .wCard) {
            VStack(alignment: .trailing, spacing: 6) {
                HStack {
                    Spacer()
                    ZStack {
                        Circle().fill(color.opacity(0.12)).frame(width: 32, height: 32)
                        Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(color)
                    }
                }
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(title).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundColor(.wLabel)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(unit).font(.wCaption).foregroundColor(.wLabelSec)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var avgGlucose: String {
        guard !health.readings.isEmpty else { return "--" }
        let avg = health.readings.map(\.valueMgdL).reduce(0, +) / Double(health.readings.count)
        return settings.glucoseUnit.displayString(avg)
    }
    private var timeInRange: String {
        guard !health.readings.isEmpty else { return "--%"}
        let n = health.readings.filter { $0.status == .normal }.count
        return "\(Int(Double(n)/Double(health.readings.count)*100))%"
    }
    private var weeklyUnits: String {
        let w = doses.doses(from: .now.addingTimeInterval(-7*86400), to: .now)
        return String(format: "%.0f", w.reduce(0) { $0 + $1.units })
    }
}

