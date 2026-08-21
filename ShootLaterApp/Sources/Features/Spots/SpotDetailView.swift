import MapKit
import SwiftData
import SwiftUI

struct SpotDetailLookupView: View {
    @Environment(\.modelContext) private var modelContext
    let id: UUID

    var body: some View {
        Group {
            if let spot = try? SpotRepository(context: modelContext).spot(id: id) {
                SpotDetailView(spot: spot)
            } else {
                ContentUnavailableView("Spot not found", systemImage: "mappin.slash")
                    .background {
                        ScoutingBackdrop()
                            .ignoresSafeArea()
                    }
            }
        }
    }
}

struct SpotDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var spot: ShootSpot
    @State private var isEditing = false
    @State private var sharePayload: SharePayload?
    @State private var confirmDelete = false

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                detailLayout(width: proxy.size.width)
                    .padding(proxy.size.width > 720 ? 28 : 16)
                    .frame(maxWidth: ShootLaterTheme.wideContentWidth)
                    .frame(maxWidth: .infinity)
            }
            .background {
                ScoutingBackdrop()
                    .ignoresSafeArea()
            }
        }
        .navigationTitle("Spot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    sharePayload = ShareCardRenderer().payload(for: spot, photo: PhotoStore().image(for: spot.photoFileName))
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share spot")
                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Edit spot")
            }
        }
        .alert("Delete this spot?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive, action: deleteSpot)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the saved spot and its app-managed photo from this device.")
        }
        .sheet(isPresented: $isEditing) {
            SpotEditView(spot: spot)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: Binding(
            get: { sharePayload.map(ShareSheetItem.init(payload:)) },
            set: { if $0 == nil { sharePayload = nil } }
        )) { item in
            ActivityView(items: item.payload.activityItems)
        }
    }

    @ViewBuilder
    private func detailLayout(width: CGFloat) -> some View {
        let useWideLayout = horizontalSizeClass == .regular && width > 780
        let heroSize = min(useWideLayout ? width * 0.42 : width - 32, 540)

        if useWideLayout {
            HStack(alignment: .top, spacing: 28) {
                hero(size: heroSize)
                    .frame(maxWidth: 540)
                detailContent
                    .frame(maxWidth: 500)
            }
        } else {
            VStack(alignment: .leading, spacing: 22) {
                hero(size: heroSize)
                    .frame(maxWidth: .infinity)
                detailContent
            }
        }
    }

    private func hero(size: CGFloat) -> some View {
        SpotThumbnail(fileName: spot.photoFileName, size: max(260, size), showSourceBadge: true, source: spot.source)
            .accessibilityLabel(spot.photoFileName == nil ? "Location-only spot artwork" : "Scouting photo")
    }

    private var detailContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            GlassPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text(spot.bestDisplayTitle)
                        .font(.largeTitle.weight(.bold))
                        .lineLimit(3)
                        .minimumScaleFactor(0.76)
                    Text(spot.displayLocation)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                    LocationStatusBadge(status: spot.locationStatus)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let notes = spot.notes?.trimmedNilIfEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeading(title: "Notes")
                    Text(notes)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(ShootLaterTheme.hairline.opacity(0.40), lineWidth: 0.5)
                }
            }

            SpotLocationMapCard(spot: spot)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                InfoTile(title: "Saved", value: spot.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                InfoTile(title: "Source", value: spot.source.label, systemImage: spot.source == .cameraCapture ? "camera.fill" : "location.fill")
                InfoTile(title: "Location", value: spot.displayLocation, systemImage: spot.coordinate == nil ? "location.slash" : "mappin.and.ellipse")
                InfoTile(title: "Status", value: spot.locationStatus.label, systemImage: spot.locationStatus == .unavailable ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
            }

            VStack(spacing: 10) {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete Spot", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("deleteSpotButton")
            }
            .padding(.top, 4)
        }
    }

    private func deleteSpot() {
        try? SpotRepository(context: modelContext).delete(spot)
        dismiss()
    }
}

private struct SpotLocationMapCard: View {
    let spot: ShootSpot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Map", subtitle: spot.coordinate == nil ? "Coordinates were not captured for this spot." : spot.displayLocation)

            if let coordinate = spot.coordinate {
                Map(initialPosition: .region(region(centeredOn: coordinate))) {
                    Marker(spot.bestDisplayTitle, coordinate: coordinate)
                        .tint(ShootLaterTheme.actionAmber)
                }
                .mapStyle(.standard(elevation: .realistic))
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(ShootLaterTheme.hairline.opacity(0.45), lineWidth: 0.5)
                }
                .accessibilityLabel("Map showing \(spot.bestDisplayTitle)")
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(ShootLaterTheme.teal)
                    Text("Location unavailable")
                        .font(.headline)
                    Text("This spot is saved, but it cannot be shown on a map.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(ShootLaterTheme.hairline.opacity(0.45), lineWidth: 0.5)
                }
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ShootLaterTheme.hairline.opacity(0.40), lineWidth: 0.5)
        }
    }

    private func region(centeredOn coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
}

struct SpotEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var spot: ShootSpot
    @State private var title: String
    @State private var notes: String

    init(spot: ShootSpot) {
        self.spot = spot
        _title = State(initialValue: spot.title ?? "")
        _notes = State(initialValue: spot.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...8)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Spot")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        spot.apply(title: title, notes: notes)
                        try? modelContext.save()
                        try? SpotRepository(context: modelContext).updateSnapshots()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ShareSheetItem: Identifiable {
    let id = UUID()
    var payload: SharePayload
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
