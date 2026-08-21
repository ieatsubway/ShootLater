import CoreLocation
import Foundation
import MapKit

struct ReverseGeocoder {
    func displayName(for location: CLLocation?) async -> String? {
        guard let location,
              let request = MKReverseGeocodingRequest(location: location) else {
            return nil
        }

        do {
            guard let mapItem = try await request.mapItems.first else { return nil }
            return [
                mapItem.name,
                mapItem.addressRepresentations?.cityWithContext(.short)
            ]
            .compactMap { $0?.trimmedNilIfEmpty }
            .removingDuplicates()
            .joined(separator: ", ")
            .trimmedNilIfEmpty
        } catch {
            return nil
        }
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
