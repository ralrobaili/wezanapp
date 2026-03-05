import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: Int, CaseIterable {
        case home, log, settings
        var label: String {
            switch self {
            case .home    : return "الرئيسية"
            case .log     : return "السجل"
            case .settings: return "الإعدادات"
            }
        }
        var icon: String {
            switch self {
            case .home    : return "house.fill"
            case .log     : return "list.bullet.clipboard"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label(Tab.home.label,     systemImage: Tab.home.icon)     }
                .tag(Tab.home)
            LogView()
                .tabItem { Label(Tab.log.label,      systemImage: Tab.log.icon)      }
                .tag(Tab.log)
            SettingsView()
                .tabItem { Label(Tab.settings.label, systemImage: Tab.settings.icon) }
                .tag(Tab.settings)
        }
        .tint(.wPrimary)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

