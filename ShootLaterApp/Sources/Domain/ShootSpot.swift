import CoreLocation
import Foundation
import SwiftData

enum SpotSource: String, Codable, CaseIterable, Identifiable {
    case cameraCapture
    case locationOnly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cameraCapture: "Camera"
        case .locationOnly: "Location"
        }
    }
}

enum LocationStatus: String, Codable, CaseIterable, Identifiable {
    case captured
    case approximate
    case unavailable
    case pendingReverseGeocode

    var id: String { rawValue }

    var label: String {
        switch self {
        case .captured: "Location captured"
        case .approximate: "Approximate location"
        case .unavailable: "Location unavailable"
        case .pendingReverseGeocode: "Naming location"
        }
    }
}

@Model
final class ShootSpot {
    var id: UUID
    var photoFileName: String?
    var latitude: Double?
    var longitude: Double?
    var locationDisplayName: String?
    var title: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    private var sourceRawValue: String
    private var locationStatusRawValue: String

    init(
        id: UUID = UUID(),
        photoFileName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationDisplayName: String? = nil,
        title: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        source: SpotSource = .locationOnly,
        locationStatus: LocationStatus = .unavailable
    ) {
        self.id = id
        self.photoFileName = photoFileName
        self.latitude = latitude
        self.longitude = longitude
        self.locationDisplayName = locationDisplayName
        self.title = title?.trimmedNilIfEmpty
        self.notes = notes?.trimmedNilIfEmpty
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sourceRawValue = source.rawValue
        self.locationStatusRawValue = locationStatus.rawValue
    }

    var source: SpotSource {
        get { SpotSource(rawValue: sourceRawValue) ?? .locationOnly }
        set { sourceRawValue = newValue.rawValue }
    }

    var locationStatus: LocationStatus {
        get { LocationStatus(rawValue: locationStatusRawValue) ?? .unavailable }
        set { locationStatusRawValue = newValue.rawValue }
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var bestDisplayTitle: String {
        if let title = title?.trimmedNilIfEmpty {
            return title
        }

        let date = Self.displayDateFormatter.string(from: createdAt)
        if let locationDisplayName = locationDisplayName?.trimmedNilIfEmpty {
            return "\(locationDisplayName) - \(date)"
        }

        return "Untitled spot - \(date)"
    }

    var displayLocation: String {
        locationDisplayName?.trimmedNilIfEmpty ?? locationStatus.label
    }

    func matchesSearch(_ query: String) -> Bool {
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return true }
        return [title, notes, locationDisplayName]
            .compactMap { $0?.lowercased() }
            .contains { $0.localizedCaseInsensitiveContains(cleaned) }
    }

    func apply(title: String?, notes: String?) {
        self.title = title?.trimmedNilIfEmpty
        self.notes = notes?.trimmedNilIfEmpty
        updatedAt = .now
    }

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

extension String {
    var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
