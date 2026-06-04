import Foundation
import Testing
@testable import ShootLater

@Suite("Share payloads")
struct ShareCardRendererTests {
    @Test("includes Apple Maps link only when exact coordinates exist")
    func mapsLinkRequiresCoordinates() {
        let renderer = ShareCardRenderer()
        let located = ShootSpot(
            latitude: 37.8199,
            longitude: -122.4783,
            locationDisplayName: "Golden Gate Bridge",
            title: "Bridge overlook",
            notes: "Try sunrise"
        )
        let unlocated = ShootSpot(locationDisplayName: "Unknown corner")

        #expect(renderer.appleMapsURL(for: located)?.absoluteString.contains("ll=37.819900,-122.478300") == true)
        #expect(renderer.appleMapsURL(for: unlocated) == nil)
    }

    @Test("share text includes optional user text only when entered")
    func shareTextIncludesOnlyEnteredFields() {
        let renderer = ShareCardRenderer()
        let spot = ShootSpot(
            locationDisplayName: "Mission Dolores Park",
            title: "Skyline grass",
            notes: "Use 85mm"
        )
        let empty = ShootSpot(locationDisplayName: "Noe Valley")

        #expect(renderer.shareText(for: spot).contains("Skyline grass"))
        #expect(renderer.shareText(for: spot).contains("Use 85mm"))
        #expect(renderer.shareText(for: empty) == "Noe Valley")
    }
}
