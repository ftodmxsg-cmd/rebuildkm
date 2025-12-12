import Foundation
import CoreLocation
import Combine

/// Manages location services for the app
/// Handles location updates, permissions, and heading information
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Published Properties
    @Published var currentLocation: CLLocation?
    @Published var heading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    @Published var isUpdatingLocation = false
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var locationUpdateHandler: ((CLLocation) -> Void)?
    
    // MARK: - Initialization
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 10 // Update every 10 meters
        locationManager.activityType = .automotiveNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Background location updates require Background Modes capability
        // Enable only if capability is configured in Xcode
        // locationManager.allowsBackgroundLocationUpdates = true
        // locationManager.showsBackgroundLocationIndicator = true
        
        authorizationStatus = locationManager.authorizationStatus
        
        print("📍 DEBUG: LocationManager initialized")
    }
    
    // MARK: - Public Methods
    
    /// Request location permissions from user
    func requestLocationPermission() {
        print("📍 DEBUG: Requesting location permission")
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }
    
    /// Start receiving location updates
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("⚠️ DEBUG: Cannot start location updates - not authorized")
            requestLocationPermission()
            return
        }
        
        print("📍 DEBUG: Starting location updates")
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    /// Stop receiving location updates
    func stopUpdatingLocation() {
        print("📍 DEBUG: Stopping location updates")
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    /// Set a handler to be called when location updates
    func setLocationUpdateHandler(_ handler: @escaping (CLLocation) -> Void) {
        locationUpdateHandler = handler
    }
    
    /// Get current location once (doesn't require continuous updates)
    func requestCurrentLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("⚠️ DEBUG: Cannot request location - not authorized")
            requestLocationPermission()
            return
        }
        
        print("📍 DEBUG: Requesting current location")
        locationManager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Only update if location is recent (within 5 seconds)
        guard location.timestamp.timeIntervalSinceNow > -5 else {
            print("⚠️ DEBUG: Location is stale, ignoring")
            return
        }
        
        // Only update if accuracy is good (within 50 meters)
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy <= 50 else {
            print("⚠️ DEBUG: Location accuracy too low: \(location.horizontalAccuracy)m")
            return
        }
        
        currentLocation = location
        locationUpdateHandler?(location)
        
        print("📍 DEBUG: Location updated - Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude), Accuracy: \(location.horizontalAccuracy)m")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Only update if heading is valid
        guard newHeading.headingAccuracy >= 0 else { return }
        
        heading = newHeading
        print("🧭 DEBUG: Heading updated - \(newHeading.trueHeading)°")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        print("❌ ERROR: Location update failed - \(error.localizedDescription)")
        
        // If location services are denied, inform user
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("❌ ERROR: Location services denied by user")
            case .locationUnknown:
                print("⚠️ DEBUG: Location currently unknown, will retry")
            default:
                break
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        print("📍 DEBUG: Authorization status changed - \(authorizationStatusString)")
        
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            print("✅ DEBUG: Location permission granted")
            if isUpdatingLocation {
                startUpdatingLocation()
            }
        case .denied, .restricted:
            print("❌ ERROR: Location permission denied or restricted")
            stopUpdatingLocation()
        case .notDetermined:
            print("⚠️ DEBUG: Location permission not yet determined")
        @unknown default:
            print("⚠️ DEBUG: Unknown authorization status")
        }
    }
    
    // MARK: - Helper Properties
    
    var authorizationStatusString: String {
        switch authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Authorized Always"
        case .authorizedWhenInUse: return "Authorized When In Use"
        @unknown default: return "Unknown"
        }
    }
    
    var isLocationAvailable: Bool {
        currentLocation != nil && (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways)
    }
}
