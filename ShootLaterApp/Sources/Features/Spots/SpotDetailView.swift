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
            }
        }
    }
}

struct SpotDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var spot: ShootSpot
    @State private var isEditing = false
    @State private var sharePayload: SharePayload?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SpotThumbnail(fileName: spot.photoFileName, size: UIScreen.main.bounds.width - 32)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 10) {
                    Text(spot.bestDisplayTitle)
                        .font(.title.bold())
                    Text(spot.displayLocation)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    LocationStatusBadge(status: spot.locationStatus)
                }

                if let notes = spot.notes?.trimmedNilIfEmpty {
                    Text(notes)
                        .font(.body)
                }

                LabeledContent("Saved", value: spot.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Source", value: spot.source.label)
            }
            .padding()
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
                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(role: .destructive) {
                try? SpotRepository(context: modelContext).delete(spot)
                dismiss()
            } label: {
                Label("Delete Spot", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding()
            .background(.thinMaterial)
        }
        .sheet(isPresented: $isEditing) {
            SpotEditView(spot: spot)
        }
        .sheet(item: Binding(
            get: { sharePayload.map(ShareSheetItem.init(payload:)) },
            set: { if $0 == nil { sharePayload = nil } }
        )) { item in
            ActivityView(items: item.payload.activityItems)
        }
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
