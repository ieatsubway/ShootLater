import MapKit
import SwiftData
import SwiftUI

struct SpotMapView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \ShootSpot.createdAt, order: .reverse) private var spots: [ShootSpot]
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedSpot: ShootSpot?
    @State private var path: [UUID] = []

    var mappedSpots: [ShootSpot] {
        spots.filter { $0.coordinate != nil }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Map(position: $cameraPosition) {
                    ForEach(mappedSpots) { spot in
                        if let coordinate = spot.coordinate {
                            Annotation(spot.bestDisplayTitle, coordinate: coordinate) {
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                        selectedSpot = spot
                                    }
                                } label: {
                                    SpotMapMarker(spot: spot, isSelected: selectedSpot?.id == spot.id)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Show \(spot.bestDisplayTitle)")
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .ignoresSafeArea(edges: .bottom)

                VStack {
                    HStack {
                        MapStatusPanel(mappedCount: mappedSpots.count, totalCount: spots.count)
                        Spacer()
                    }
                    Spacer()
                }
                .padding()

                if mappedSpots.isEmpty {
                    EmptyScoutingState(
                        title: "No mapped spots yet",
                        message: spots.isEmpty ? "Capture a spot or save your location to start building a scouting map." : "Saved spots without coordinates stay in your list, but they cannot appear on the map.",
                        systemImage: "map"
                    )
                    .background(.white.opacity(0.28), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .padding()
                }

                if let selectedSpot {
                    previewLayout(for: selectedSpot)
                }
            }
            .navigationTitle("Map")
            .navigationDestination(for: UUID.self) { id in
                SpotDetailLookupView(id: id)
            }
        }
    }

    @ViewBuilder
    private func previewLayout(for spot: ShootSpot) -> some View {
        if horizontalSizeClass == .regular {
            HStack {
                Spacer()
                MapSpotPreview(
                    spot: spot,
                    onOpen: { path = [spot.id] },
                    onDismiss: { withAnimation { selectedSpot = nil } }
                )
                .frame(width: 370)
                .padding(.trailing, 22)
            }
            .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            VStack {
                Spacer()
                MapSpotPreview(
                    spot: spot,
                    onOpen: { path = [spot.id] },
                    onDismiss: { withAnimation { selectedSpot = nil } }
                )
                .frame(maxWidth: 440)
                .padding()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

struct MapSpotPreview: View {
    let spot: ShootSpot
    let onOpen: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    SpotThumbnail(fileName: spot.photoFileName, size: 92, showSourceBadge: true, source: spot.source)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(spot.bestDisplayTitle)
                            .font(.headline)
                            .lineLimit(3)
                        Text(spot.displayLocation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        MetadataPill(title: spot.createdAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    Button(action: onOpen) {
                        Label("Open Spot", systemImage: "arrow.up.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .frame(width: 42, height: 42)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Dismiss spot preview")
                }
            }
        }
    }
}

struct SpotMapMarker: View {
    let spot: ShootSpot
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            SpotThumbnail(fileName: spot.photoFileName, size: isSelected ? 58 : 48, showSourceBadge: false, source: spot.source)
                .overlay {
                    RoundedRectangle(cornerRadius: isSelected ? 14 : 12, style: .continuous)
                        .stroke(isSelected ? ShootLaterTheme.amber : .white, lineWidth: isSelected ? 3 : 2)
                }
            Image(systemName: "triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? ShootLaterTheme.amber : .white)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
        .shadow(color: .black.opacity(0.24), radius: 10, y: 6)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isSelected)
    }
}

struct MapStatusPanel: View {
    let mappedCount: Int
    let totalCount: Int

    var body: some View {
        GlassPanel(cornerRadius: 18) {
            HStack(spacing: 10) {
                Image(systemName: "map.fill")
                    .foregroundStyle(ShootLaterTheme.teal)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(mappedCount) mapped")
                        .font(.subheadline.weight(.bold))
                    Text(totalCount == mappedCount ? "All saved spots" : "\(totalCount - mappedCount) without coordinates")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
