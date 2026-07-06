import SwiftUI

struct HomeView: View {

    @EnvironmentObject var health  : HealthKitService
    @EnvironmentObject var doses   : DoseStore
    @EnvironmentObject var settings: SettingsStore

    @State private var showAddDose = false
    @State private var chartRange  : ChartRange = .h6
    @State private var showToast   = false
    @State private var toastMsg    = ""
    @State private var siriTimer   : Timer?

    enum ChartRange: String, CaseIterable {
        case h3 = "3س"; case h6 = "6س"; case h24 = "24س"
        var hours: Double { switch self { case .h3: 3; case .h6: 6; case .h24: 24 } }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color.wBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        glucoseCard
                        doseCard
                        chartCard
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, WSpacing.lg)
                    .padding(.top, 8)
                }

                if showToast {
                    VStack {
                        WToast(msg: toastMsg).padding(.top, 60)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.4), value: showToast)
            .navigationTitle("مستوى السكر")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showAddDose) { AddDoseSheet() }
        .onAppear {
            health.checkAuthStatus()
            if health.isAuthorized {
                Task { await health.startMonitoring() }
            } else {
                Task { await health.requestAuthorization() }
            }
            startSiriMonitor()
        }
        .onDisappear { siriTimer?.invalidate() }
    }

    private var glucoseCard: some View {
        WCard(padding: 20, bg: .wCard) {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    WStatusChip(status: currentStatus)
                }
                .padding(.bottom, 6)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Spacer()
                    Text(currentGlucoseStr)
                        .font(.wGlucoseLg)
                        .foregroundColor(.wLabel)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.4), value: currentGlucoseStr)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settings.glucoseUnit.label)
                            .font(.wUnit)
                            .foregroundColor(.wLabelSec)
                        trendArrow
                    }
                }

                HStack {
                    Spacer()
                    if let r = health.latestReading {
                        HStack(spacing: 5) {
                            Circle().fill(Color.wNormal).frame(width: 6, height: 6)
                            Text("Apple Health · \(timeStr(r.timestamp))")
                                .font(.wCaption).foregroundColor(.wLabelSec)
                        }
                    } else {
                        Text("لا توجد بيانات — تحقق من HealthKit")
                            .font(.wCaption).foregroundColor(.wLabelSec)
                    }
                }
                .padding(.top, 8)

                Divider().padding(.vertical, 14)

                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("النطاق المستهدف").font(.wCaption).foregroundColor(.wLabelSec)
                        HStack(spacing: 4) {
                            Text(settings.glucoseUnit.displayString(settings.targetLow))
                            Text("–")
                            Text(settings.glucoseUnit.displayString(settings.targetHigh))
                            Text(settings.glucoseUnit.label)
                        }
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.wNormal)
                    }
                }
            }
        }
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    private var doseCard: some View {
        WCard(padding: 20, bg: .wCard) {
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("آخر جرعة إنسولين").font(.wCaption).foregroundColor(.wLabelSec)
                        if let last = doses.doses.first {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(Int(last.units)) وحدات")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.wLabel)
                                Text(settings.glucoseUnit.label)
                                    .font(.wCaption).foregroundColor(.wLabelSec)
                            }
                            Text(timeAgoStr(last.timestamp))
                                .font(.wCaption).foregroundColor(.wLabelSec)
                        } else {
                            Text("لا توجد جرعات مسجّلة")
                                .font(.wListItem).foregroundColor(.wLabelSec)
                        }
                    }
                }
                WPrimaryBtn("تسجيل جرعة جديدة", icon: "syringe") { showAddDose = true }
            }
        }
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    private var chartCard: some View {
        WCard(padding: 20, bg: .wCard) {
            VStack(alignment: .trailing, spacing: 14) {
                HStack {
                    HStack(spacing: 4) {
                        ForEach(ChartRange.allCases, id: \.self) { r in
                            Button {
                                withAnimation { chartRange = r }
                                Task { await health.fetchReadings(hours: r.hours) }
                            } label: {
                                Text(r.rawValue)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(chartRange == r ? .wPrimary : .wLabelSec)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(chartRange == r ? Color.wTint1 : Color.clear)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .animation(.spring(duration: 0.2), value: chartRange)
                        }
                    }
                    Spacer()
                    Text("مخطط السكر في الدم").font(.wCardTitle).foregroundColor(.wLabel)
                }

                if health.readings.count >= 2 {
                    GlucoseSparkline(
                        readings  : health.readings,
                        unit      : settings.glucoseUnit,
                        targetLow : settings.targetLow,
                        targetHigh: settings.targetHigh,
                        height    : 110
                    )
                    HStack {
                        ForEach([0, health.readings.count / 2, health.readings.count - 1], id: \.self) { i in
                            if i < health.readings.count {
                                Text(timeStr(health.readings[i].timestamp))
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(.wLabelSec)
                                if i < health.readings.count - 1 { Spacer() }
                            }
                        }
                    }
                    HStack {
                        chartStat(label: "الأعلى",
                                  value: health.readings.map(\.valueMgdL).max().map { settings.glucoseUnit.displayString($0) } ?? "--",
                                  color: .wHigh)
                        Spacer()
                        chartStat(label: "المتوسط",
                                  value: { let avg = health.readings.map(\.valueMgdL).reduce(0,+) / Double(health.readings.count); return settings.glucoseUnit.displayString(avg) }(),
                                  color: .wPrimary)
                        Spacer()
                        chartStat(label: "الأدنى",
                                  value: health.readings.map(\.valueMgdL).min().map { settings.glucoseUnit.displayString($0) } ?? "--",
                                  color: .wLow)
                    }
                    .padding(.top, 4)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.xyaxis.line").font(.system(size: 32)).foregroundColor(.wLabelSec.opacity(0.3))
                        Text("لا توجد بيانات كافية").font(.wCaption).foregroundColor(.wLabelSec)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 30)
                }

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles").font(.system(size: 13)).foregroundColor(.wPrimary)
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("تحليل البيانات")
                            .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.wPrimary)
                        Text(insightText)
                            .font(.system(size: 11, design: .rounded)).foregroundColor(.wLabelSec)
                            .lineSpacing(3).multilineTextAlignment(.trailing)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.wTint1)
                .clipShape(RoundedRectangle(cornerRadius: WRadius.md, style: .continuous))
            }
        }
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    private func chartStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundColor(color)
            Text(label).font(.wCaption).foregroundColor(.wLabelSec)
        }
    }

    private var trendArrow: some View {
        let r = health.readings
        guard r.count >= 2 else { return Text("").font(.wCaption).foregroundColor(.clear) }
        let up = r.last!.valueMgdL > r[r.count - 2].valueMgdL
        return Text(up ? "↑" : "↓")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(up ? .wHigh : .wNormal)
    }

    private var currentGlucoseStr: String {
        guard let r = health.latestReading else { return "--" }
        return r.display(settings.glucoseUnit)
    }
    private var currentStatus: GlucoseStatus {
        guard let r = health.latestReading else { return .normal }
        return r.status
    }
    private var insightText: String {
        let h = Calendar.current.component(.hour, from: .now)
        if (7...9).contains(h)   { return "لاحظنا ارتفاع السكر في هذا الوقت من الصباح. ناقش الجرعة الليلية مع طبيبك." }
        if (12...14).contains(h) { return "حان وقت قياس السكر قبل الغداء إن لم تكن قد فعلت ذلك." }
        if (20...23).contains(h) { return "تذكّر الجرعة الليلية الطويلة إن كانت جزءاً من خطة علاجك." }
        return "استمر في تسجيل جرعاتك يومياً ليتمكن طبيبك من ضبط خطة العلاج بدقة."
    }
    private func timeStr(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: d)
    }
    private func timeAgoStr(_ d: Date) -> String {
        let m = Int(-d.timeIntervalSinceNow / 60)
        if m < 1  { return "الآن" }
        if m < 60 { return "منذ \(m) دقيقة" }
        let h = m / 60
        if h < 24 { return "منذ \(h) ساعة" } //
        return "منذ \(h/24) يوم"
    }
    private func startSiriMonitor() {
        siriTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            Task { @MainActor in
                guard let d = SiriDoseBridge.shared.pendingDose else { return }
                SiriDoseBridge.shared.pendingDose = nil
                doses.add(d)
                toastMsg  = "✅ سيري سجّل \(Int(d.units)) وحدة \(d.insulinType.rawValue)"
                showToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { showToast = false }
            }
        }
    }
}
