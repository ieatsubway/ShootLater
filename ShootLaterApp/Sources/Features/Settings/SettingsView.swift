import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationService.self) private var locationService
    @Query private var spots: [ShootSpot]
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            List {
                Section("Permissions") {
                    HStack {
                        Label("Location", systemImage: "location.fill")
                        Spacer()
                        Text(locationLabel)
                            .foregroundStyle(.secondary)
                    }
                    Button("Request Location Access") {
                        locationService.requestAuthorization()
                    }
                }

                Section("Privacy") {
                    Text("ShootLater stores exact coordinates and photos locally on this device. Share cards show a general location while Apple Maps links use coordinates only when you choose to share.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete All Spots", systemImage: "trash")
                    }
                }
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
