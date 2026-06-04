import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case capture
    case map
    case spots
    case settings

    var id: String { rawValue }
}

enum AppRoute: Hashable {
    case spot(UUID)
}

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .capture
    var captureRequested = false
    var pendingSpotID: UUID?

    func handle(url: URL) {
        guard url.scheme == AppConstants.urlScheme else { return }
        if url.host == "capture" {
            selectedTab = .capture
            captureRequested = true
            return
        }

        if url.host == "spot",
           let idString = url.pathComponents.dropFirst().first,
           let id = UUID(uuidString: idString) {
            selectedTab = .spots
            pendingSpotID = id
        }
    }
}
