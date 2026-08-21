import Foundation
import SwiftData
import Testing
import UIKit
@testable import ShootLater

@Suite("ShootSpot domain behavior")
struct ShootSpotTests {
    @Test("uses title as the best display title when present")
    func titleWinsDisplayName() {
        let spot = ShootSpot(
            locationDisplayName: "Mission District",
            title: "Blue wall",
            notes: nil,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            source: .cameraCapture,
            locationStatus: .captured
        )

        #expect(spot.bestDisplayTitle == "Blue wall")
    }

    @Test("falls back to location and date when no title is present")
    func locationAndDateFallback() {
        let spot = ShootSpot(
            locationDisplayName: "Downtown Oakland",
            title: nil,
            notes: nil,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            source: .locationOnly,
            locationStatus: .captured
        )

        #expect(spot.bestDisplayTitle.contains("Downtown Oakland"))
        #expect(spot.bestDisplayTitle.contains("2023"))
    }

    @Test("search matches title notes and human location")
    func searchMatchesUserFacingFields() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ShootSpot.self, configurations: config)
        let context = ModelContext(container)
        let repository = SpotRepository(context: context)

        let titleSpot = ShootSpot(locationDisplayName: "SoMa", title: "Neon alley", notes: nil)
        let notesSpot = ShootSpot(locationDisplayName: "Hayes Valley", title: nil, notes: "Great soft backlight")
        let placeSpot = ShootSpot(locationDisplayName: "Presidio", title: nil, notes: nil)
        context.insert(titleSpot)
        context.insert(notesSpot)
        context.insert(placeSpot)
        try context.save()

        #expect(try repository.search("neon").map(\.id) == [titleSpot.id])
        #expect(try repository.search("backlight").map(\.id) == [notesSpot.id])
        #expect(try repository.search("presidio").map(\.id) == [placeSpot.id])
    }

    @Test("repository delete removes SwiftData spot and app-managed photo")
    func repositoryDeleteRemovesSpotAndPhoto() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ShootSpot.self, configurations: config)
        let context = ModelContext(container)
        let repository = SpotRepository(context: context)
        let photoRoot = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let photoStore = PhotoStore(rootDirectory: photoRoot)
        let photoFileName = try photoStore.save(UIImage(systemName: "mappin.and.ellipse")!)

        let spot = try repository.create(
            photoFileName: photoFileName,
            latitude: 37.7749,
            longitude: -122.4194,
            locationDisplayName: "San Francisco",
            source: .cameraCapture,
            locationStatus: .captured
        )

        #expect(try repository.spot(id: spot.id) != nil)
        #expect(FileManager.default.fileExists(atPath: photoStore.url(for: photoFileName).path()))

        try repository.delete(spot, photoStore: photoStore)

        #expect(try repository.spot(id: spot.id) == nil)
        #expect(!FileManager.default.fileExists(atPath: photoStore.url(for: photoFileName).path()))
    }
}
