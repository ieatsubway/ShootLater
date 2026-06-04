import MapKit
import SwiftData
import SwiftUI

struct SpotMapView: View {
    @Query(sort: \ShootSpot.createdAt, order: .reverse) private var spots: [ShootSpot]
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedSpot: ShootSpot?

    var mappedSpots: [ShootSpot] {
        spots.filter { $0.coordinate != nil }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    ForEach(mappedSpots) { spot in
                        if let coordinate = spot.coordinate {
                            Annotation(spot.bestDisplayTitle, coordinate: coordinate) {
                                Button {
                                    selectedSpot = spot
                                } label: {
                                    SpotThumbnail(fileName: spot.photoFileName, size: 44)
                                        .shadow(radius: 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .ignoresSafeArea(edges: .bottom)

                if let selectedSpot {
                    MapSpotPreview(spot: selectedSpot)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Map")
        }
    }
}

struct MapSpotPreview: View {
    let spot: ShootSpot

    var body: some View {
        NavigationLink(value: spot.id) {
            HStack(spacing: 14) {
                SpotThumbnail(fileName: spot.photoFileName, size: 76)
                VStack(alignment: .leading, spacing: 5) {
                    Text(spot.bestDisplayTitle)
                        .font(.headline)
                        .lineLimit(2)
                    Text(spot.displayLocation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(spot.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .navigationDestination(for: UUID.self) { id in
            SpotDetailLookupView(id: id)
        }
    }
}
