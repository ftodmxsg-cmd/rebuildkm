import SwiftUI
import GoogleMaps
import CoreLocation

/// Enhanced map view for navigation with route display
/// Rule 0: Simple map component that displays routes and user location
struct NavigationMapView: UIViewRepresentable {
    let route: Route?
    let userLocation: CLLocation?
    let userHeading: CLHeading?
    
    func makeUIView(context: Context) -> GMSMapView {
        // Default to Singapore
        let defaultLocation = CLLocationCoordinate2D(latitude: 1.2840, longitude: 103.8607)
        let camera = GMSCameraPosition.camera(
            withLatitude: defaultLocation.latitude,
            longitude: defaultLocation.longitude,
            zoom: 15.0
        )
        
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.delegate = context.coordinator
        
        // Map settings optimized for navigation
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = false // We'll use custom button
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = true
        
        print("🗺️ DEBUG: Navigation map view created")
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Update route if changed
        if let route = route {
            drawRoute(on: mapView, route: route)
            
            // Fit map to show entire route
            if !context.coordinator.hasZoomedToRoute {
                zoomToRoute(mapView, route: route)
                context.coordinator.hasZoomedToRoute = true
            }
        }
        
        // Update user location marker if needed
        if let location = userLocation, let heading = userHeading {
            updateUserLocationMarker(on: mapView, location: location, heading: heading, context: context)
        }
        
        // Center on user location if navigating
        if let location = userLocation, route != nil {
            // Smoothly animate to user location
            let update = GMSCameraUpdate.setTarget(location.coordinate, zoom: 17)
            mapView.animate(with: update)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Private Methods
    
    private func drawRoute(on mapView: GMSMapView, route: Route) {
        // Remove old polyline if exists
        mapView.clear()
        
        // Decode polyline
        let coordinates = PolylineDecoder.decode(route.polyline)
        
        guard !coordinates.isEmpty else {
            print("⚠️ WARNING: No coordinates in route polyline")
            return
        }
        
        // Create path
        let path = GMSMutablePath()
        coordinates.forEach { path.add($0) }
        
        // Create polyline
        let polyline = GMSPolyline(path: path)
        polyline.strokeColor = .systemBlue
        polyline.strokeWidth = 5
        polyline.geodesic = true
        polyline.map = mapView
        
        // Add start marker
        let startMarker = GMSMarker()
        startMarker.position = coordinates.first!
        startMarker.title = "Start"
        startMarker.icon = GMSMarker.markerImage(with: .systemGreen)
        startMarker.map = mapView
        
        // Add end marker
        let endMarker = GMSMarker()
        endMarker.position = coordinates.last!
        endMarker.title = "Destination"
        endMarker.snippet = route.endAddress
        endMarker.icon = GMSMarker.markerImage(with: .systemRed)
        endMarker.map = mapView
        
        print("🗺️ DEBUG: Route drawn with \(coordinates.count) points")
    }
    
    private func zoomToRoute(_ mapView: GMSMapView, route: Route) {
        let bounds = GMSCoordinateBounds(
            coordinate: route.bounds.southwest,
            coordinate: route.bounds.northeast
        )
        
        let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
        mapView.animate(with: update)
        
        print("🗺️ DEBUG: Map zoomed to fit route")
    }
    
    private func updateUserLocationMarker(on mapView: GMSMapView, location: CLLocation, heading: CLHeading, context: Context) {
        // Use built-in location dot, but we could customize this
        // The blue dot will automatically show with isMyLocationEnabled = true
        
        // Rotate map based on heading for better navigation experience
        let bearing = heading.trueHeading
        if bearing >= 0 { // Valid heading
            let camera = GMSCameraPosition.camera(
                withLatitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                zoom: mapView.camera.zoom,
                bearing: bearing,
                viewingAngle: 45 // Slight tilt for 3D effect
            )
            mapView.animate(to: camera)
        }
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var hasZoomedToRoute = false
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            // Show info window when marker tapped
            mapView.selectedMarker = marker
            return true
        }
    }
}

// MARK: - Preview

struct NavigationMapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationMapView(
            route: nil,
            userLocation: nil,
            userHeading: nil
        )
        .edgesIgnoringSafeArea(.all)
    }
}

