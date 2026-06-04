import SwiftData
import SwiftUI

struct SpotsListView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \ShootSpot.createdAt, order: .reverse) private var spots: [ShootSpot]
    @State private var searchText = ""
    @State private var path: [UUID] = []

    private var filteredSpots: [ShootSpot] {
        let cleaned = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return spots }
        return spots.filter { $0.matchesSearch(cleaned) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            List(filteredSpots) { spot in
                NavigationLink(value: spot.id) {
                    SpotRow(spot: spot)
                }
            }
            .overlay {
                if spots.isEmpty {
                    ContentUnavailableView(
                        "No spots yet",
                        systemImage: "camera.fill",
                        description: Text("Capture a photo spot or save your current location.")
                    )
                }
            }
            .navigationTitle("Spots")
            .searchable(text: $searchText, prompt: "Search title, notes, or location")
            .navigationDestination(for: UUID.self) { id in
                SpotDetailLookupView(id: id)
            }
            .onChange(of: router.pendingSpotID) { _, id in
                guard let id else { return }
                path = [id]
                router.pendingSpotID = nil
            }
        }
    }
}

struct SpotRow: View {
    let spot: ShootSpot

    var body: some View {
        HStack(spacing: 12) {
            SpotThumbnail(fileName: spot.photoFileName, size: 58)
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.bestDisplayTitle)
                    .font(.headline)
                    .lineLimit(1)
                Text(spot.displayLocation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(spot.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
