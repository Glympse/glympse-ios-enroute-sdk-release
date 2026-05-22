import SwiftUI
import CoreLocation
import Combine

class LocationAuthManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = LocationAuthManager()
    private let manager = CLLocationManager()
    let locationPublisher = PassthroughSubject<CLLocation, Error>()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isBackgroundLocationAuthorized: Bool = false
    @AppStorage("didRequestAlwaysPermission") private var didRequestAlwaysPermission: Bool = false

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestBackgroundLocationAuthorization() {
        if authorizationStatus == .notDetermined {
            logger.debug("LocationManager: Requesting When In Use authorization first.")
            manager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse && !didRequestAlwaysPermission {
            logger.debug("LocationManager: Already authorized for When In Use. Requesting Always authorization.")
            manager.requestAlwaysAuthorization()
            didRequestAlwaysPermission = true
        } else {
            logger.debug("LocationManager: Authorization status is: \(authorizationStatus.description)")
            openAppSettings()
        }
    }
    
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            logger.warning("LocationManager: Failed to open app settings.")
            return
        }
        
        UIApplication.shared.open(settingsUrl, options: [:]) { success in
            if success {
                logger.debug("LocationManager: App settings opened successfully.")
            } else {
                logger.warning("LocationManager: Failed to open app settings with valid url")
            }
        }
    }

    func checkBackgroundStatus() {
        isBackgroundLocationAuthorized = (manager.authorizationStatus == .authorizedAlways)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        logger.debug("LocationManager: Authorization status changed to: \(authorizationStatus.description)")

        switch authorizationStatus {
        case .authorizedAlways:
            logger.debug("LocationManager: Authorized for Always (Background Location).")
            isBackgroundLocationAuthorized = true
            // You can now start background location updates if needed and configured.
        case .authorizedWhenInUse:
            logger.debug("LocationManager: Authorized for When In Use.")
            isBackgroundLocationAuthorized = false
        case .denied:
            logger.debug("LocationManager: Authorization denied.")
            isBackgroundLocationAuthorized = false
        case .restricted:
            logger.debug("LocationManager: Authorization restricted (e.g., by parental controls).")
            isBackgroundLocationAuthorized = false
        case .notDetermined:
            logger.debug("LocationManager: Authorization not determined.")
            isBackgroundLocationAuthorized = false
        @unknown default:
            logger.debug("LocationManager: Unknown authorization status.")
            isBackgroundLocationAuthorized = false
        }
    }
}

extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Authorized Always"
        case .authorizedWhenInUse: return "Authorized When In Use"
        @unknown default: return "Unknown"
        }
    }
}

