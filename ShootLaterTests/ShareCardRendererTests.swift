import Foundation
import SwiftUI
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

    @MainActor
    @Test("renders location-only share card for long place names")
    func rendersLongLocationOnlyCard() {
        let renderer = ShareCardRenderer()
        let spot = ShootSpot(
            locationDisplayName: "A very long scouting location near the northwest corner of the old industrial warehouse district"
        )

        let image = renderer.renderCard(for: spot, photo: nil)

        #expect(image.size == CGSize(width: 1_080, height: 1_080))
    }

    @MainActor
    @Test("scouting backdrop and accent adapt to light and dark appearances")
    func scoutingPaletteAdaptsToAppearance() {
        let base = UIColor(ShootLaterTheme.backdropBase)
        let accent = UIColor(ShootLaterTheme.actionAmber)
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let darkTraits = UITraitCollection(userInterfaceStyle: .dark)
        let lightBaseLuminance = luminance(of: base.resolvedColor(with: lightTraits))
        let darkBaseLuminance = luminance(of: base.resolvedColor(with: darkTraits))
        let lightAccent = rgba(of: accent.resolvedColor(with: lightTraits))
        let darkAccent = rgba(of: accent.resolvedColor(with: darkTraits))

        #expect(lightBaseLuminance > 0.85)
        #expect(darkBaseLuminance < 0.18)
        #expect(lightAccent.red > lightAccent.blue)
        #expect(lightAccent.green > lightAccent.blue)
        #expect(darkAccent.red > darkAccent.blue)
        #expect(darkAccent.green > darkAccent.blue)
    }

    private func luminance(of color: UIColor) -> CGFloat {
        let components = rgba(of: color)
        return (components.red * 0.299) + (components.green * 0.587) + (components.blue * 0.114)
    }

    private func rgba(of uiColor: UIColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
}
