import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(LocationService.self) private var locationService
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        @Bindable var router = router

        ZStack {
            ScoutingBackdrop()
                .ignoresSafeArea()

            if hasSeenOnboarding {
                MainTabView(selectedTab: $router.selectedTab)
            } else {
                OnboardingView {
                    locationService.requestAuthorization()
                    hasSeenOnboarding = true
                }
            }
        }
        .background(ShootLaterTheme.backdropBase.ignoresSafeArea())
    }
}

struct MainTabView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Capture", systemImage: "camera", value: AppTab.capture) {
                CaptureView()
            }

            Tab("Map", systemImage: "map", value: AppTab.map) {
                SpotMapView()
            }

            Tab("Library", systemImage: "rectangle.stack", value: AppTab.spots) {
                SpotsListView(mode: .library)
            }

            Tab("Search", systemImage: "magnifyingglass", value: AppTab.search, role: .search) {
                SpotsListView(mode: .search)
            }
        }
        .tint(ShootLaterTheme.amber)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewSearchActivation(.searchTabSelection)
    }
}

struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let compactOnboarding = proxy.size.height < 900
            ZStack {
                ScoutingBackdrop()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: compactOnboarding ? 10 : 22) {
                        AppMark(size: compactOnboarding ? 54 : 96)
                            .padding(.top, compactOnboarding ? 10 : 28)

                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(ShootLaterTheme.scoutingGradient)
                            .frame(maxWidth: 460)
                            .frame(height: compactOnboarding ? 146 : 238)
                            .overlay(alignment: .bottomLeading) {
                                VStack(alignment: .leading, spacing: compactOnboarding ? 8 : 10) {
                                    Label("Private scouting", systemImage: "location.viewfinder")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, compactOnboarding ? 6 : 8)
                                        .glassEffect(.regular, in: Capsule())

                                    Text("Save the place now. Shape the shoot later.")
                                        .font((compactOnboarding ? Font.headline : .title2).weight(.bold))
                                        .foregroundStyle(.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(compactOnboarding ? 18 : 22)
                            }

                        VStack(spacing: compactOnboarding ? 8 : 12) {
                            Text("ShootLater")
                                .font((compactOnboarding ? Font.title2 : .largeTitle).weight(.bold))

                            Button(action: onContinue) {
                                Label("Set Up Location", systemImage: "location.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: compactOnboarding ? 46 : 50)
                            }
                            .buttonStyle(.glassProminent)
                            .tint(ShootLaterTheme.primaryAction)
                            .frame(maxWidth: 420)
                            .padding(.top, 4)

                            Text("Private local scouting. Exact coordinates stay on this device.")
                                .font(compactOnboarding ? .footnote : .body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: 520)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height, alignment: .center)
                }
            }
        }
    }
}
