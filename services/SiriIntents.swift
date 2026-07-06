import AppIntents
import Foundation

struct LogInsulinDoseIntent: AppIntent {

    static var title: LocalizedStringResource = "تسجيل جرعة إنسولين"
    static var description = IntentDescription("سجّل جرعة إنسولين بصوتك عبر سيري")

    @Parameter(
        title: "عدد الوحدات",
        requestValueDialog: "كم وحدة تريد تسجيلها؟"
    )
    var units: Double

    @Parameter(title: "نوع الإنسولين", default: "سريع")
    var typeName: String?

    static var parameterSummary: some ParameterSummary {
        Summary("سجّل \(\.$units) وحدة إنسولين")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let type: InsulinType = {
            switch typeName?.lowercased() {
            case "طويل", "بطيء", "long": return .long
            case "مختلط", "mixed"      : return .mixed
            default                    : return .rapid
            }
        }()
        let dose = DoseRecord(
            units      : units,
            insulinType: type,
            timestamp  : .now,
            note       : "عبر سيري"
        )
        await SiriDoseBridge.shared.save(dose)
        return .result(dialog: "تم تسجيل \(Int(units)) وحدة \(type.rawValue) ✅")
    }
}

// MARK: – Shortcuts provider
// الحل: بدون [] — كل AppShortcut على سطر مستقل مع @AppShortcutsBuilder
struct WazanShortcuts: AppShortcutsProvider {

    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogInsulinDoseIntent(),
            phrases: [
                "سجّل جرعة في \(.applicationName)",
                "سجّل لي جرعة في \(.applicationName)",
                "\(.applicationName) سجّل جرعة"
            ],
            shortTitle: "تسجيل جرعة",
            systemImageName: "syringe"
        )
    }
}

// 
@MainActor
final class SiriDoseBridge {

    static let shared = SiriDoseBridge()
    private init() {}

    private let defaults = UserDefaults(suiteName: "group.com.yourname.wezanapp")
    private let key = "siri.pending"

    func save(_ dose: DoseRecord) {
        guard let data = try? JSONEncoder().encode(dose) else { return }
        defaults?.set(data, forKey: key)
    }

    var pendingDose: DoseRecord? {
        get {
            guard let d = defaults?.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(DoseRecord.self, from: d)
        }
        set {
            if let v = newValue, let d = try? JSONEncoder().encode(v) {
                defaults?.set(d, forKey: key)
            } else {
                defaults?.removeObject(forKey: key)
            }
        }
    }
}
