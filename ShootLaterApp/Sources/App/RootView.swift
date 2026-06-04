import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(LocationService.self) private var locationService
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        @Bindable var router = router

        Group {
            if hasSeenOnboarding {
                MainTabView(selectedTab: $router.selectedTab)
            } else {
                OnboardingView {
                    locationService.requestAuthorization()
                    hasSeenOnboarding = true
                }
            }
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            CaptureView()
                .tabItem { Label("Capture", systemImage: "camera.fill") }
                .tag(AppTab.capture)

            SpotMapView()
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(AppTab.map)

            SpotsListView()
                .tabItem { Label("Spots", systemImage: "rectangle.stack.fill") }
                .tag(AppTab.spots)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
    }
}

struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "camera.metering.center.weighted")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 118, height: 118)
                .background(.teal.gradient, in: Circle())

            VStack(spacing: 12) {
                Text("ShootLater")
                    .font(.largeTitle.bold())
                Text("Save places you may want to photograph later. Location stays private on this device and helps you rediscover the spot when you need it.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: onContinue) {
                Label("Set Up Location", systemImage: "location.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .padding(.horizontal, 28)

            Spacer()
        }
        .padding()
        .background(.background)
    }
}
