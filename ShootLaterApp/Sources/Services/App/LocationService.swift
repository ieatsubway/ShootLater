import CoreLocation
import Foundation

@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    enum AuthorizationState {
        case unknown
        case allowed
        case denied
    }

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    var authorizationState: AuthorizationState = .unknown
    var lastKnownLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        updateAuthorizationState()
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() async -> CLLocation? {
        updateAuthorizationState()
        guard authorizationState == .allowed else { return nil }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            updateAuthorizationState()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            lastKnownLocation = locations.last
            continuation?.resume(returning: locations.last)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(returning: nil)
            continuation = nil
        }
    }

    private func updateAuthorizationState() {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            authorizationState = .allowed
        case .denied, .restricted:
            authorizationState = .denied
        case .notDetermined:
            authorizationState = .unknown
        @unknown default:
            authorizationState = .unknown
        }
    }
}
