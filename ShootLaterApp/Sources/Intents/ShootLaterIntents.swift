import AppIntents
import Foundation

struct CaptureNewSpotIntent: AppIntent {
    static let title: LocalizedStringResource = "Capture New Spot"
    static let description = IntentDescription("Open ShootLater directly into camera capture.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct SaveCurrentLocationIntent: AppIntent {
    static let title: LocalizedStringResource = "Save Current Location"
    static let description = IntentDescription("Open ShootLater to save a location-only scouting spot.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct OpenSpotIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Spot"
    static let description = IntentDescription("Open a saved ShootLater spot.")
    static let openAppWhenRun = true

    @Parameter(title: "Spot ID")
    var spotID: String

    init() {
        self.spotID = ""
    }

    init(spotID: UUID) {
        self.spotID = spotID.uuidString
    }

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct ShootLaterShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureNewSpotIntent(),
            phrases: [
                "Capture in \(.applicationName)",
                "Save a shoot spot in \(.applicationName)"
            ],
            shortTitle: "Capture Spot",
            systemImageName: "camera.fill"
        )
        AppShortcut(
            intent: SaveCurrentLocationIntent(),
            phrases: [
                "Save my location in \(.applicationName)",
                "Scout this place in \(.applicationName)"
            ],
            shortTitle: "Save Location",
            systemImageName: "location.fill"
        )
    }
}
