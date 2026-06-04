import CoreLocation
import SwiftData
import SwiftUI
import UIKit

struct PendingCapture: Identifiable {
    let id = UUID()
    var image: UIImage?
    var source: SpotSource
}

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationService.self) private var locationService
    @Environment(AppRouter.self) private var router
    @State private var pendingCapture: PendingCapture?
    @State private var isCameraPresented = false
    @State private var isSavingLocation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 14) {
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 68, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 132, height: 132)
                        .background(.teal.gradient, in: Circle())
                        .glassEffect(.regular, in: Circle())

                    Text("Save a scouting spot")
                        .font(.title.bold())
                    Text("Take a quick reference photo or save your current location without stopping to type.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 14) {
                    Button {
                        isCameraPresented = true
                    } label: {
                        Label("Capture New Spot", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)

                    Button {
                        Task { await saveLocationOnly() }
                    } label: {
                        Label(isSavingLocation ? "Saving Location" : "Save Current Location", systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSavingLocation)
                }
                .padding(.horizontal, 28)

                LocationStatusBadge(status: locationService.authorizationState == .denied ? .unavailable : .pendingReverseGeocode)

                Spacer()
            }
            .navigationTitle("Capture")
            .fullScreenCover(isPresented: $isCameraPresented) {
                CameraCaptureView { image in
                    isCameraPresented = false
                    pendingCapture = PendingCapture(image: image, source: .cameraCapture)
                } onCancel: {
                    isCameraPresented = false
                }
                .ignoresSafeArea()
            }
            .sheet(item: $pendingCapture) { capture in
                CaptureConfirmationView(capture: capture)
            }
            .onChange(of: router.captureRequested) { _, requested in
                if requested {
                    isCameraPresented = true
                    router.captureRequested = false
                }
            }
        }
    }

    private func saveLocationOnly() async {
        isSavingLocation = true
        defer { isSavingLocation = false }
        let location = await locationService.requestCurrentLocation()
        let displayName = await ReverseGeocoder().displayName(for: location)
        let repository = SpotRepository(context: modelContext)
        try? repository.create(
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            locationDisplayName: displayName,
            source: .locationOnly,
            locationStatus: location == nil ? .unavailable : (displayName == nil ? .pendingReverseGeocode : .captured)
        )
    }
}

struct CaptureConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationService.self) private var locationService
    let capture: PendingCapture
    @State private var title = ""
    @State private var notes = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let image = capture.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }

                Section("Optional") {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Save Spot")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let location = await locationService.requestCurrentLocation()
        let displayName = await ReverseGeocoder().displayName(for: location)
        let fileName = try? capture.image.map { try PhotoStore().save($0) }
        let repository = SpotRepository(context: modelContext)
        try? repository.create(
            photoFileName: fileName ?? nil,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            locationDisplayName: displayName,
            title: title,
            notes: notes,
            source: capture.source,
            locationStatus: location == nil ? .unavailable : (displayName == nil ? .pendingReverseGeocode : .captured)
        )
        dismiss()
    }
}
