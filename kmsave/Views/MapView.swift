import SwiftUI
import GoogleMaps

struct MapView: View {
    @State private var isMapReady = false
    var route: Route?
    var currentLocation: CLLocation?
    var showUserLocation: Bool = true
    
    var body: some View {
        ZStack {
            GoogleMapView(
                isReady: $isMapReady,
                route: route,
                currentLocation: currentLocation,
                showUserLocation: showUserLocation
            )
            .edgesIgnoringSafeArea(.all)
            
            if !isMapReady {
                ProgressView("Loading Map...")
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
            }
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GoogleMapView: UIViewRepresentable {
    @Binding var isReady: Bool
    var route: Route?
    var currentLocation: CLLocation?
    var showUserLocation: Bool
    
    // Default location: Singapore (Marina Bay Sands)
    private let defaultLocation = CLLocationCoordinate2D(
        latitude: 1.2840,
        longitude: 103.8607
    )
    
    func makeUIView(context: Context) -> GMSMapView {
        // Create camera positioned at Singapore or current location
        let cameraLocation = currentLocation?.coordinate ?? defaultLocation
        let camera = GMSCameraPosition.camera(
            withLatitude: cameraLocation.latitude,
            longitude: cameraLocation.longitude,
            zoom: 15.0
        )
        
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.delegate = context.coordinator
        
        // Map settings
        mapView.isMyLocationEnabled = showUserLocation
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = true
        
        // For navigation, set appropriate settings
        if route != nil {
            mapView.settings.scrollGestures = true
            mapView.settings.zoomGestures = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isReady = true
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Clear existing overlays
        mapView.clear()
        
        // Draw route if available
        if let route = route {
            drawRoute(on: mapView, route: route)
        } else {
            // Add a marker at default location if no route
            let marker = GMSMarker()
            marker.position = defaultLocation
            marker.title = "Singapore"
            marker.snippet = "Marina Bay Sands"
            marker.map = mapView
        }
        
        // Update camera to show current location if available
        if let location = currentLocation, route == nil {
            let camera = GMSCameraPosition.camera(
                withLatitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                zoom: 15.0
            )
            mapView.animate(to: camera)
        }
    }
    
    // MARK: - Route Drawing
    
    private func drawRoute(on mapView: GMSMapView, route: Route) {
        // Draw route polyline
        if let path = GMSPath(fromEncodedPath: route.polyline) {
            let polyline = GMSPolyline(path: path)
            polyline.strokeWidth = 6
            polyline.strokeColor = .systemBlue
            polyline.geodesic = true
            polyline.map = mapView
            
            print("🗺️ DEBUG: Route polyline drawn with \(path.count()) points")
            
            // Fit camera to show entire route
            let bounds = route.bounds.gmsBounds
            let update = GMSCameraUpdate.fit(bounds, withPadding: 80)
            mapView.animate(with: update)
        }
        
        // Add destination marker
        if let lastStep = route.steps.last {
            let destinationMarker = GMSMarker()
            destinationMarker.position = lastStep.endLocation.clCoordinate
            destinationMarker.title = "Destination"
            destinationMarker.icon = GMSMarker.markerImage(with: .red)
            destinationMarker.map = mapView
            print("🗺️ DEBUG: Destination marker added")
        }
        
        // Add start marker
        if let firstStep = route.steps.first {
            let startMarker = GMSMarker()
            startMarker.position = firstStep.startLocation.clCoordinate
            startMarker.title = "Start"
            startMarker.icon = GMSMarker.markerImage(with: .green)
            startMarker.map = mapView
            print("🗺️ DEBUG: Start marker added")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView
        
        init(_ parent: GoogleMapView) {
            self.parent = parent
        }
        
        func mapViewDidFinishTileRendering(_ mapView: GMSMapView) {
            parent.isReady = true
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}

