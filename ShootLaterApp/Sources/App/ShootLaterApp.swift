import SwiftData
import SwiftUI

@main
struct ShootLaterApp: App {
    @State private var router = AppRouter()
    @State private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(locationService)
                .modelContainer(AppModelContainer.shared)
                .onOpenURL { router.handle(url: $0) }
        }
    }
}
