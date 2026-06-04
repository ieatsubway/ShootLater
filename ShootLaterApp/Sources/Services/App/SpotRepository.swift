import Foundation
import SwiftData

struct SpotRepository {
    let context: ModelContext

    func all() throws -> [ShootSpot] {
        var descriptor = FetchDescriptor<ShootSpot>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.includePendingChanges = true
        return try context.fetch(descriptor)
    }

    func search(_ query: String) throws -> [ShootSpot] {
        let spots = try all()
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return spots }
        return spots.filter { $0.matchesSearch(cleaned) }
    }

    func spot(id: UUID) throws -> ShootSpot? {
        let descriptor = FetchDescriptor<ShootSpot>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    @discardableResult
    func create(
        photoFileName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationDisplayName: String? = nil,
        title: String? = nil,
        notes: String? = nil,
        source: SpotSource,
        locationStatus: LocationStatus
    ) throws -> ShootSpot {
        let spot = ShootSpot(
            photoFileName: photoFileName,
            latitude: latitude,
            longitude: longitude,
            locationDisplayName: locationDisplayName,
            title: title,
            notes: notes,
            source: source,
            locationStatus: locationStatus
        )
        context.insert(spot)
        try context.save()
        try updateSnapshots()
        return spot
    }

    func delete(_ spot: ShootSpot, photoStore: PhotoStore = PhotoStore()) throws {
        try photoStore.delete(fileName: spot.photoFileName)
        context.delete(spot)
        try context.save()
        try updateSnapshots()
    }

    func updateSnapshots() throws {
        let snapshots = try all().map {
            SpotSnapshot(
                id: $0.id,
                title: $0.bestDisplayTitle,
                location: $0.displayLocation,
                createdAt: $0.createdAt,
                photoFileName: $0.photoFileName,
                isLocationOnly: $0.source == .locationOnly
            )
        }
        try SpotSnapshotStore().save(snapshots)
    }
}
