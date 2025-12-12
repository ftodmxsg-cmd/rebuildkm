import SwiftUI
import CoreLocation
import GoogleMaps

/// View for selecting destination and viewing route preview
struct RouteSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationManager: LocationManager
    @State private var directionsService: DirectionsService
    
    @State private var destinationAddress = ""
    @State private var isLoadingRoute = false
    @State private var route: Route?
    @State private var errorMessage: String?
    @State private var showingNavigationView = false
    
    // Sample destinations for Singapore
    private let suggestedDestinations = [
        ("Marina Bay Sands", CLLocationCoordinate2D(latitude: 1.2840, longitude: 103.8607)),
        ("Changi Airport", CLLocationCoordinate2D(latitude: 1.3644, longitude: 103.9915)),
        ("Sentosa", CLLocationCoordinate2D(latitude: 1.2494, longitude: 103.8303)),
        ("Orchard Road", CLLocationCoordinate2D(latitude: 1.3048, longitude: 103.8318))
    ]
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        // Get API key from environment or plist
        let apiKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"] 
            ?? Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String 
            ?? ""
        _directionsService = State(initialValue: DirectionsService(apiKey: apiKey))
    }
    
    var body: some View {
        ZStack {
            // Background map preview
            if let route = route {
                RoutePreviewMap(route: route, currentLocation: locationManager.currentLocation)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.gray.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                // Header
                header
                
                Spacer()
                
                // Bottom sheet with route info
                bottomSheet
            }
        }
        .onAppear {
            locationManager.requestLocationPermission()
            locationManager.startUpdatingLocation()
        }
        .sheet(isPresented: $showingNavigationView) {
            if let route = route {
                ActiveNavigationView(route: route, locationManager: locationManager)
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Bottom Sheet
    
    private var bottomSheet: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text("Where to?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Current location
                    currentLocationSection
                    
                    // Suggested destinations
                    suggestedDestinationsSection
                    
                    // Route preview
                    if let route = route {
                        routeInfoSection(route: route)
                    }
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Start navigation button
                    if route != nil {
                        startNavigationButton
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
    }
    
    // MARK: - Current Location Section
    
    private var currentLocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Current Location", systemImage: "location.fill")
                .font(.headline)
                .foregroundColor(.blue)
            
            if let location = locationManager.currentLocation {
                Text("Lat: \(location.coordinate.latitude, specifier: "%.4f"), Lon: \(location.coordinate.longitude, specifier: "%.4f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Fetching your location...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Suggested Destinations
    
    private var suggestedDestinationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Destinations")
                .font(.headline)
            
            ForEach(suggestedDestinations, id: \.0) { destination in
                Button(action: {
                    fetchRoute(to: destination.1, name: destination.0)
                }) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(destination.0)
                            .foregroundColor(.primary)
                        Spacer()
                        if isLoadingRoute {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(10)
                }
                .disabled(isLoadingRoute)
            }
        }
    }
    
    // MARK: - Route Info Section
    
    private func routeInfoSection(route: Route) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Overview")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text(route.distance.text)
                        .font(.headline)
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Image(systemName: "clock.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    Text(route.duration.text)
                        .font(.headline)
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text("\(route.steps.count)")
                        .font(.headline)
                    Text("Steps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Start Navigation Button
    
    private var startNavigationButton: some View {
        Button(action: {
            showingNavigationView = true
        }) {
            HStack {
                Image(systemName: "location.fill")
                Text("Start Navigation")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchRoute(to destination: CLLocationCoordinate2D, name: String) {
        guard let origin = locationManager.currentLocation?.coordinate else {
            errorMessage = "Current location not available"
            return
        }
        
        isLoadingRoute = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedRoute = try await directionsService.fetchRoute(from: origin, to: destination)
                await MainActor.run {
                    self.route = fetchedRoute
                    self.isLoadingRoute = false
                    print("✅ DEBUG: Route to \(name) loaded successfully")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch route: \(error.localizedDescription)"
                    self.isLoadingRoute = false
                    print("❌ ERROR: Failed to fetch route - \(error)")
                }
            }
        }
    }
}

// MARK: - Route Preview Map

struct RoutePreviewMap: UIViewRepresentable {
    let route: Route
    let currentLocation: CLLocation?
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: 1.3521, longitude: 103.8198, zoom: 11)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.isMyLocationEnabled = true
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Clear existing overlays
        mapView.clear()
        
        // Draw route polyline
        if let path = GMSPath(fromEncodedPath: route.polyline) {
            let polyline = GMSPolyline(path: path)
            polyline.strokeWidth = 5
            polyline.strokeColor = .systemBlue
            polyline.map = mapView
            
            // Fit camera to show entire route
            let bounds = route.bounds.gmsBounds
            let update = GMSCameraUpdate.fit(bounds, withPadding: 80)
            mapView.animate(with: update)
        }
        
        // Add destination marker
        if let lastStep = route.steps.last {
            let marker = GMSMarker()
            marker.position = lastStep.endLocation.clCoordinate
            marker.title = "Destination"
            marker.icon = GMSMarker.markerImage(with: .red)
            marker.map = mapView
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
