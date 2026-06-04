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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(LocationService.self) private var locationService
    @Environment(AppRouter.self) private var router
    @State private var pendingCapture: PendingCapture?
    @State private var isCameraPresented = false
    @State private var isSavingLocation = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let compactHeight = proxy.size.height < 900

                ZStack {
                    ScoutingBackdrop()
                        .ignoresSafeArea()

                    ScrollView {
                        captureLayout(width: proxy.size.width, height: proxy.size.height)
                            .padding(.horizontal, proxy.size.width > 720 ? 32 : 20)
                            .padding(.vertical, compactHeight ? 14 : 28)
                            .frame(maxWidth: ShootLaterTheme.wideContentWidth)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: proxy.size.height, alignment: compactHeight ? .top : .center)
                    }
                    .contentMargins(.bottom, compactHeight ? 124 : 24, for: .scrollContent)
                    .background(.clear)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: router.captureRequested) { _, requested in
                if requested {
                    isCameraPresented = true
                    router.captureRequested = false
                }
            }
        }
    }

    @ViewBuilder
    private func captureLayout(width: CGFloat, height: CGFloat) -> some View {
        let useWideLayout = horizontalSizeClass == .regular || width > 720
        let compactHeight = height < 900

        if useWideLayout {
            HStack(alignment: .center, spacing: 28) {
                captureIntro(compact: compactHeight)
                    .frame(maxWidth: 470, alignment: .leading)
                captureActions(compact: compactHeight)
                    .frame(maxWidth: 420)
            }
        } else {
            VStack(spacing: compactHeight ? 12 : 28) {
                captureIntro(compact: compactHeight)
                captureActions(compact: compactHeight)
                    .frame(maxWidth: 460)
            }
        }
    }

    private func captureIntro(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 14 : 20) {
            AppMark(size: compact ? 54 : 118)

            VStack(alignment: .leading, spacing: 10) {
                Text("Save a scouting spot")
                    .font((compact ? Font.title2 : .largeTitle).weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                Text(compact ? "Capture a reference photo or save your current location." : "Take a reference photo or save your current location in seconds. No title or notes required.")
                    .font(compact ? .footnote : .body)
                    .foregroundStyle(ShootLaterTheme.ink.opacity(0.72))
                    .lineLimit(compact ? 2 : nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func captureActions(compact: Bool) -> some View {
        VStack(spacing: 14) {
            if compact {
                HStack(spacing: 12) {
                    Button {
                        isCameraPresented = true
                    } label: {
                        Label("Capture", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(ShootLaterTheme.actionAmber)
                    .accessibilityIdentifier("captureNewSpotButton")

                    Button {
                        Task { await saveLocationOnly() }
                    } label: {
                        Label(isSavingLocation ? "Saving" : "Location", systemImage: "location.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                    }
                    .buttonStyle(.glass)
                    .disabled(isSavingLocation)
                    .accessibilityIdentifier("saveCurrentLocationButton")
                }
            } else {
                Button {
                    isCameraPresented = true
                } label: {
                    Label("Capture New Spot", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 54)
                }
                .buttonStyle(.glassProminent)
                .tint(ShootLaterTheme.actionAmber)
                .accessibilityIdentifier("captureNewSpotButton")

                Button {
                    Task { await saveLocationOnly() }
                } label: {
                    Label(isSavingLocation ? "Saving Location" : "Save Current Location", systemImage: "location.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                }
                .buttonStyle(.glass)
                .disabled(isSavingLocation)
                .accessibilityIdentifier("saveCurrentLocationButton")
            }

            if compact {
                HStack {
                    LocationStatusBadge(status: locationService.authorizationState == .denied ? .unavailable : .pendingReverseGeocode)
                    Spacer(minLength: 0)
                }
            } else {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(
                            title: "Ready when you are",
                            subtitle: "Coordinates stay private unless you choose to share an Apple Maps link."
                        )
                        LocationStatusBadge(status: locationService.authorizationState == .denied ? .unavailable : .pendingReverseGeocode)
                    }
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
        _ = try? repository.create(
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
            .scrollDismissesKeyboard(.interactively)
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
        _ = try? repository.create(
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
