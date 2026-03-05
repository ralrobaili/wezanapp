import SwiftUI

@main
struct WezanAppApp: App {

    @StateObject private var health   = HealthKitService()
    @StateObject private var doses    = DoseStore()
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(health)
                .environmentObject(doses)
                .environmentObject(settings)
        }
    }
}

// MARK: – Root: يقرر يعرض Onboarding أو التطبيق
struct RootView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var health  : HealthKitService

    var body: some View {
        ContentView()
            .task {
                health.checkAuthStatus()
                if health.isAuthorized {
                    await health.startMonitoring()
                }
            }
            .fullScreenCover(isPresented: .constant(!settings.hasOnboarded)) {
                OnboardingView()
            }
    }
}
