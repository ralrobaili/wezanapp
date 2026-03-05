import SwiftUI

struct LogView: View {
    @EnvironmentObject var doseStore: DoseStore
    @EnvironmentObject var settings : SettingsStore

    @State private var doseToDelete : DoseRecord?
    @State private var confirmDelete = false

    var body: some View {
        NavigationView {
            Group {
                if doseStore.doses.isEmpty {
                    emptyState
                } else {
                    logList
                }
            }
            .background(Color.wBg.ignoresSafeArea())
            .navigationTitle("السجل")
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog("حذف الجرعة؟", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("حذف", role: .destructive) {
                if let d = doseToDelete { doseStore.delete(d) }
            }
            Button("إلغاء", role: .cancel) {}
        } message: {
            if let d = doseToDelete {
                Text("سيتم حذف تسجيل \(Int(d.units)) وحدة نهائياً.")
            }
        }
    }

    // MARK: – List
    private var logList: some View {
        List {
            ForEach(doseStore.groupedByDay, id: \.key) { group in
                Section {
                    ForEach(group.doses) { dose in
                        doseRow(dose)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.wCard)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    doseToDelete = dose
                                    confirmDelete = true
                                } label: {
                                    Label("حذف", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    // ✅ header محاذاة يمين
                    Text(group.key)
                        .font(.wCaption)
                        .foregroundColor(.wLabelSec)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, WSpacing.md)
                        .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: – Row — محاذاة يمين كاملة
    private func doseRow(_ dose: DoseRecord) -> some View {
        HStack(spacing: 12) {
            // الوقت — يسار
            VStack(alignment: .leading, spacing: 2) {
                Text(timeStr(dose.timestamp))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.wLabelSec)
                if let g = dose.glucoseAtDose {
                    Text(settings.glucoseUnit.displayString(g) + " " + settings.glucoseUnit.label)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(GlucoseStatus(mgdL: g).color)
                }
            }

            Spacer()

            // المعلومات — يمين
            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 6) {
                    Text(dose.insulinType.rawValue)
                        .font(.wCaption).foregroundColor(.wLabelSec)
                    Text("\(Int(dose.units)) وحدات")
                        .font(.wListBold).foregroundColor(.wLabel)
                }
                if !dose.note.isEmpty {
                    Text(dose.note)
                        .font(.wCaption).foregroundColor(.wLabelSec)
                }
            }

            // أيقونة النوع
            ZStack {
                Circle()
                    .fill(dose.insulinType.color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: dose.insulinType.sfSymbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(dose.insulinType.color)
            }
        }
        .padding(.horizontal, WSpacing.md)
        .padding(.vertical, 12)
    }

    // MARK: – Empty
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "list.clipboard")
                .font(.system(size: 48)).foregroundColor(.wLabelSec.opacity(0.3))
            Text("لا توجد جرعات مسجّلة بعد")
                .font(.wCardTitle).foregroundColor(.wLabelSec)
            Text("سجّل جرعتك من صفحة الرئيسية")
                .font(.wBody).foregroundColor(.wLabelTer)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func timeStr(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: d)
    }
}
