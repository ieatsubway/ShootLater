import SwiftData
import SwiftUI

enum SpotsPresentationMode: Equatable {
    case library
    case search
}

struct SpotsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppRouter.self) private var router
    @Query(sort: \ShootSpot.createdAt, order: .reverse) private var spots: [ShootSpot]
    let mode: SpotsPresentationMode
    @State private var searchText = ""
    @State private var path: [UUID] = []
    @State private var isShowingSettings = false

    private var filteredSpots: [ShootSpot] {
        guard mode == .search else { return spots }
        let cleaned = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return spots }
        return spots.filter { $0.matchesSearch(cleaned) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if horizontalSizeClass == .regular {
                    spotGrid
                } else {
                    spotList
                }
            }
            .navigationTitle(mode == .search ? "Search" : "Library")
            .modifier(SpotSearchModifier(isEnabled: mode == .search, text: $searchText))
            .toolbar {
                if mode == .library {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                SpotDetailLookupView(id: id)
            }
            .onAppear(perform: consumePendingSpot)
            .onChange(of: router.pendingSpotID) { _, _ in consumePendingSpot() }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
    }

    private var spotList: some View {
        List {
            ForEach(filteredSpots) { spot in
                NavigationLink(value: spot.id) {
                    SpotRow(spot: spot)
                }
            }
            .onDelete(perform: deleteSpots)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(ScoutingBackdrop().ignoresSafeArea())
        .overlay { emptyState }
    }

    private var spotGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 250, maximum: 340), spacing: 18)],
                alignment: .center,
                spacing: 18
            ) {
                ForEach(filteredSpots) { spot in
                    NavigationLink(value: spot.id) {
                        SpotCard(spot: spot)
                            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteSpot(id: spot.id)
                        } label: {
                            Label("Delete Spot", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .frame(maxWidth: ShootLaterTheme.wideContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(ScoutingBackdrop().ignoresSafeArea())
        .overlay { emptyState }
    }

    @ViewBuilder
    private var emptyState: some View {
        if spots.isEmpty {
            EmptyScoutingState(
                title: "No spots yet",
                message: "Capture a photo spot or save your current location to build your scouting library."
            )
        } else if filteredSpots.isEmpty {
            EmptyScoutingState(
                title: "No matching spots",
                message: "Try a title, note, or broader location.",
                systemImage: "magnifyingglass"
            )
        }
    }

    private func consumePendingSpot() {
        guard mode == .library else { return }
        guard let id = router.pendingSpotID else { return }
        path = [id]
        router.pendingSpotID = nil
    }

    private func deleteSpots(at offsets: IndexSet) {
        let deletedIDs = offsets.compactMap { index in
            filteredSpots.indices.contains(index) ? filteredSpots[index].id : nil
        }
        let repository = SpotRepository(context: modelContext)

        for id in deletedIDs {
            guard let spot = try? repository.spot(id: id) else { continue }
            try? repository.delete(spot)
        }

        path.removeAll { deletedIDs.contains($0) }
    }

    private func deleteSpot(id: UUID) {
        guard let spot = try? SpotRepository(context: modelContext).spot(id: id) else { return }
        try? SpotRepository(context: modelContext).delete(spot)
    }
}

private struct SpotSearchModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var text: String

    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(
                text: $text,
                placement: .automatic,
                prompt: "Title, notes, or location"
            )
        } else {
            content
        }
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
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        metadata
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        metadata
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens spot details")
    }

    @ViewBuilder
    private var metadata: some View {
        MetadataPill(title: spot.createdAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
        MetadataPill(title: spot.source.label, systemImage: spot.source == .cameraCapture ? "camera.fill" : "location.fill")
    }
}
