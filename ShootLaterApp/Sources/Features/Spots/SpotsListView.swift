import SwiftData
import SwiftUI

struct SpotsListView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppRouter.self) private var router
    @Query(sort: \ShootSpot.createdAt, order: .reverse) private var spots: [ShootSpot]
    @State private var searchText = ""
    @State private var path: [UUID] = []
    @State private var selectedSpotID: UUID?

    private var filteredSpots: [ShootSpot] {
        let cleaned = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return spots }
        return spots.filter { $0.matchesSearch(cleaned) }
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            regularLayout
        } else {
            compactLayout
        }
    }

    private var compactLayout: some View {
        NavigationStack(path: $path) {
            spotList
            .navigationTitle("Spots")
            .searchable(text: $searchText, prompt: "Search title, notes, or location")
            .navigationDestination(for: UUID.self) { id in
                SpotDetailLookupView(id: id)
            }
            .onAppear(perform: consumePendingSpot)
            .onChange(of: router.pendingSpotID) { _, id in
                guard let id else { return }
                path = [id]
                router.pendingSpotID = nil
            }
        }
    }

    private var regularLayout: some View {
        NavigationSplitView {
            spotList
                .navigationTitle("Spots")
                .searchable(text: $searchText, prompt: "Search title, notes, or location")
                .onAppear {
                    if selectedSpotID == nil {
                        selectedSpotID = filteredSpots.first?.id
                    }
                    consumePendingSpot()
                }
                .onChange(of: router.pendingSpotID) { _, id in
                    guard let id else { return }
                    selectedSpotID = id
                    router.pendingSpotID = nil
                }
        } detail: {
            if let selectedSpotID {
                NavigationStack {
                    SpotDetailLookupView(id: selectedSpotID)
                }
            } else {
                EmptyScoutingState(
                    title: "Choose a spot",
                    message: spots.isEmpty ? "Capture your first scouting spot to see details here." : "Select a saved spot to inspect photos, notes, and sharing actions.",
                    systemImage: "rectangle.stack"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    ScoutingBackdrop()
                        .ignoresSafeArea()
                }
            }
        }
    }

    private var spotList: some View {
        List(selection: $selectedSpotID) {
            ForEach(filteredSpots) { spot in
                NavigationLink(value: spot.id) {
                    SpotRow(spot: spot)
                }
                .tag(spot.id)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background {
            ScoutingBackdrop()
                .ignoresSafeArea()
        }
        .overlay {
            if spots.isEmpty {
                EmptyScoutingState(
                    title: "No spots yet",
                    message: "Capture a photo spot or save your current location to build your scouting library."
                )
            } else if filteredSpots.isEmpty {
                EmptyScoutingState(
                    title: "No matching spots",
                    message: "Try searching by a title, note, or broader location.",
                    systemImage: "magnifyingglass"
                )
            }
        }
    }

    private func consumePendingSpot() {
        guard let id = router.pendingSpotID else { return }
        if horizontalSizeClass == .regular {
            selectedSpotID = id
        } else {
            path = [id]
        }
        router.pendingSpotID = nil
    }
}

struct SpotRow: View {
    let spot: ShootSpot

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            SpotThumbnail(fileName: spot.photoFileName, size: 68, showSourceBadge: true, source: spot.source)
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.bestDisplayTitle)
                    .font(.headline)
                    .lineLimit(2)
                Text(spot.displayLocation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    MetadataPill(title: spot.createdAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    MetadataPill(title: spot.source.label, systemImage: spot.source == .cameraCapture ? "camera.fill" : "location.fill")
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
    }
}
