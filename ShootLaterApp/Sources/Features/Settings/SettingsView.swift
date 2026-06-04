import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationService.self) private var locationService
    @Query private var spots: [ShootSpot]
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            AppMark(size: 70)
                            SectionHeading(
                                title: "Private by default",
                                subtitle: "ShootLater stores scouting photos, notes, and exact coordinates locally on this device."
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: "Permissions", subtitle: "Location helps each spot remember where it was captured.")
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: locationService.authorizationState == .denied ? "location.slash" : "location.fill")
                                        .font(.headline)
                                        .foregroundStyle(ShootLaterTheme.teal)
                                        .frame(width: 34, height: 34)
                                        .background(ShootLaterTheme.mist, in: Circle())
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Location")
                                            .font(.headline)
                                        Text(locationLabel)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer(minLength: 0)
                                }

                                Button("Request Location Access") {
                                    locationService.requestAuthorization()
                                }
                                .buttonStyle(.glass)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: "Sharing", subtitle: "Share cards show the general place name. Apple Maps links include exact coordinates only when you share a located spot.")
                        InfoTile(title: "Saved spots", value: "\(spots.count)", systemImage: "rectangle.stack")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: "Destructive actions")
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Label("Delete All Spots", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("deleteAllSpotsButton")
                    }
                }
                .padding()
                .frame(maxWidth: ShootLaterTheme.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .background {
                ScoutingBackdrop()
                    .ignoresSafeArea()
            }
            .navigationTitle("Settings")
            .alert("Delete all spots?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    deleteAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes saved spots and app-managed photos from this device.")
            }
        }
    }

    private var locationLabel: String {
        switch locationService.authorizationState {
        case .unknown: "Not requested"
        case .allowed: "Allowed"
        case .denied: "Denied"
        }
    }

    private func deleteAll() {
        let repository = SpotRepository(context: modelContext)
        for spot in spots {
            try? PhotoStore().delete(fileName: spot.photoFileName)
            modelContext.delete(spot)
        }
        try? modelContext.save()
        try? repository.updateSnapshots()
    }
}
