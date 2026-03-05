import SwiftUI

struct AddDoseSheet: View {
    @Environment(\.dismiss)  private var dismiss
    @EnvironmentObject var doseStore    : DoseStore
    @EnvironmentObject var healthService: HealthKitService
    @EnvironmentObject var settings     : SettingsStore

    @State private var units: Double = 4

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // ── مستوى السكر الحالي
                    if let r = healthService.latestReading {
                        HStack(spacing: 10) {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.wPrimary)
                            Text("مستوى السكر الحالي")
                                .font(.wCaption).foregroundColor(.wLabelSec)
                            Spacer()
                            Text(r.display(settings.glucoseUnit))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(r.status.color)
                            Text(settings.glucoseUnit.label)
                                .font(.wCaption).foregroundColor(.wLabelSec)
                        }
                        .padding(14)
                        .background(Color.wTint1)
                        .clipShape(RoundedRectangle(cornerRadius: WRadius.md, style: .continuous))
                    }

                    // ── عدد الوحدات فقط
                    WCard(bg: .wCard) {
                        VStack(spacing: 24) {
                            Text("عدد الوحدات")
                                .font(.wCaption).foregroundColor(.wLabelSec)
                                .frame(maxWidth: .infinity, alignment: .trailing)

                            HStack(spacing: 40) {
                                // ناقص
                                Button {
                                    withAnimation(.spring(duration: 0.2)) { units = max(0.5, units - 1) }
                                } label: {
                                    ZStack {
                                        Circle().fill(Color.wBg).frame(width: 56, height: 56)
                                        Image(systemName: "minus")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(.wPrimary)
                                    }
                                }
                                .buttonStyle(.plain)

                                // الرقم
                                VStack(spacing: 2) {
                                    Text(String(format: "%.0f", units))
                                        .font(.system(size: 72, weight: .bold, design: .rounded))
                                        .foregroundColor(.wPrimary)
                                        .contentTransition(.numericText())
                                        .animation(.spring(duration: 0.25), value: units)
                                    Text("وحدة")
                                        .font(.wCaption).foregroundColor(.wLabelSec)
                                }

                                // زائد
                                Button {
                                    withAnimation(.spring(duration: 0.2)) { units += 1 }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(colors: [.wPrimary, .wAccent], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 56, height: 56)
                                        Image(systemName: "plus")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .shadow(color: Color.wPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .buttonStyle(.plain)
                            }

                            // Presets
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                                ForEach([2.0,4.0,6.0,8.0,10.0,12.0,16.0,20.0], id: \.self) { p in
                                    Button {
                                        withAnimation(.spring(duration: 0.2)) { units = p }
                                    } label: {
                                        Text(String(format: "%.0f", p))
                                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                                            .foregroundColor(units == p ? .white : .wPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(units == p ? Color.wPrimary : Color.wTint1)
                                            .clipShape(RoundedRectangle(cornerRadius: WRadius.sm, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.spring(duration: 0.2), value: units)
                                }
                            }
                        }
                    }

                    WPrimaryBtn("تسجيل الجرعة", icon: "checkmark") { save() }
                }
                .padding(.horizontal, WSpacing.lg)
                .padding(.bottom, 40)
                .padding(.top, 8)
            }
            .background(Color.wBg.ignoresSafeArea())
            .navigationTitle("جرعة جديدة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") { dismiss() }
                        .foregroundColor(.wPrimary)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func save() {
        // ✅ افتراضي دائماً سريع المفعول
        let d = DoseRecord(
            units        : units,
            insulinType  : .rapid,
            timestamp    : .now,
            glucoseAtDose: healthService.latestReading?.valueMgdL
        )
        doseStore.add(d)
        dismiss()
    }
}
