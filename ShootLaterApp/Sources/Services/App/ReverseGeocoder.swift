import CoreLocation
import Foundation

struct ReverseGeocoder {
    private let geocoder = CLGeocoder()

    func displayName(for location: CLLocation?) async -> String? {
        guard let location else { return nil }
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            return [
                placemark.name,
                placemark.locality,
                placemark.administrativeArea
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
