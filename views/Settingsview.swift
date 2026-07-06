import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var health  : HealthKitService
    @EnvironmentObject var doses   : DoseStore
    @EnvironmentObject var settings: SettingsStore

    @State private var exportRange    : ExportRange = .month
    @State private var isExporting    = false
    @State private var exportDone     = false
    @State private var exportURL      : URL?
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            List {

                Section {
                    healthKitRow
                }

                Section("وحدة السكر") {
                    unitRow
                }

                Section("تصدير البيانات") {
                    exportRow
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.wBg.ignoresSafeArea())
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                HStack {
                    Spacer()
                    Text("الإعدادات")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.wLabel)
                        .padding(.trailing, WSpacing.lg)
                        .padding(.top, 16)
                }
                .background(Color.wBg)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL { ShareSheet(url: url) }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: – Apple Health
    private var healthKitRow: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.systemRed).opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.red)
            }
            VStack(alignment: .trailing, spacing: 3) {
                Text("Apple Health")
                    .font(.wListBold).foregroundColor(.wLabel)
                Text(health.isAuthorized ? "متصل — يقرأ بيانات السكر" : "اضغط لتفعيل الوصول")
                    .font(.wCaption).foregroundColor(.wLabelSec)
            }
            Spacer()
            HStack(spacing: 5) {
                Circle()
                    .fill(health.isAuthorized ? Color.wNormal : Color.wLow)
                    .frame(width: 7, height: 7)
                Text(health.statusLabel)
                    .font(.wCaption)
                    .foregroundColor(health.isAuthorized ? .wNormal : .wLow)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !health.isAuthorized { Task { await health.requestAuthorization() } }
        }
    }

    private var unitRow: some View {
        HStack(spacing: 10) {
            ForEach(GlucoseUnit.allCases, id: \.self) { u in
                Button {
                    withAnimation(.spring(duration: 0.25)) { settings.glucoseUnit = u }
                } label: {
                    VStack(spacing: 4) {
                        Text(u.rawValue)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(settings.glucoseUnit == u ? .wPrimary : .wLabelSec)
                        Text(u == .mgdL ? "الأكثر شيوعاً" : "الوحدة الدولية")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.wLabelSec)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(settings.glucoseUnit == u ? Color.wTint1 : Color.wBg)
                    .clipShape(RoundedRectangle(cornerRadius: WRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: WRadius.md, style: .continuous)
                            .stroke(settings.glucoseUnit == u ? Color.wPrimary.opacity(0.5) : Color.wCardStroke, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }

    private var exportRow: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("اختر الفترة الزمنية")
                .font(.wCaption).foregroundColor(.wLabelSec)
                .frame(maxWidth: .infinity, alignment: .trailing)

            HStack(spacing: 8) {
                ForEach(ExportRange.allCases) { r in
                    Button {
                        withAnimation { exportRange = r }
                    } label: {
                        Text(r.rawValue)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(exportRange == r ? .white : .wPrimary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(exportRange == r ? Color.wPrimary : Color.wTint1)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(duration: 0.2), value: exportRange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            HStack(spacing: 5) {
                Image(systemName: "info.circle").font(.system(size: 11)).foregroundColor(.wPrimary)
                Text("\(doses.doses(from: exportRange.startDate, to: .now).count) جرعة ستُصدَّر")
                    .font(.wCaption).foregroundColor(.wPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            Button { runExport() } label: {
                HStack(spacing: 8) {
                    if isExporting {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    } else {
                        Image(systemName: exportDone ? "checkmark" : "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(exportDone ? "تم التصدير!" : isExporting ? "جاري الإنشاء..." : "تصدير الآن")
                        .font(.wButton)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(exportDone ? Color.wNormal : isExporting ? Color.wPrimary.opacity(0.6) : Color.wPrimary)
                .clipShape(RoundedRectangle(cornerRadius: WRadius.md, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isExporting)
            .animation(.spring(duration: 0.3), value: exportDone)
            .padding(.bottom, 4)
        }
        .padding(.vertical, 8)
    }

    private func runExport() {
        isExporting = true
        let d = doses.doses(from: exportRange.startDate, to: .now)
        Task {
            let readings = await health.fetchReadings(from: exportRange.startDate, to: .now)
            let url = PDFExportService.generate(doses: d, readings: readings, range: exportRange, unit: settings.glucoseUnit)
            await MainActor.run {
                isExporting = false
                if let url {
                    exportURL = url; showShareSheet = true
                    exportDone = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { exportDone = false }
                }
            }
        }
    }
}
