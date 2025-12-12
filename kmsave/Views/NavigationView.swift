import SwiftUI
import CoreLocation
import GoogleMaps

/// Main navigation view with turn-by-turn guidance
struct ActiveNavigationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var navigationEngine: NavigationEngine
    @StateObject private var voiceGuidance = VoiceGuidanceService()
    @ObservedObject var locationManager: LocationManager
    
    @State private var isNavigating = false
    @State private var showingExitConfirmation = false
    
    init(route: Route, locationManager: LocationManager) {
        self.locationManager = locationManager
        _navigationEngine = StateObject(wrappedValue: NavigationEngine(route: route))
    }
    
    var body: some View {
        ZStack {
            // Full-screen map
            NavigationMapView(
                navigationState: navigationEngine.navigationState,
                currentLocation: locationManager.currentLocation
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Instruction banner at top
                instructionBanner
                
                Spacer()
                
                // Stats bar at bottom
                statsBar
            }
            
            // Exit button (top left)
            VStack {
                HStack {
                    exitButton
                    Spacer()
                }
                Spacer()
            }
            .padding()
        }
        .onAppear {
            startNavigation()
        }
        .onDisappear {
            stopNavigation()
        }
        .alert("Exit Navigation?", isPresented: $showingExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                stopNavigation()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to stop navigation?")
        }
    }
    
    // MARK: - Instruction Banner
    
    private var instructionBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Maneuver icon
                if let currentStep = navigationEngine.navigationState.currentStep {
                    Image(systemName: currentStep.maneuver.iconName)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Distance to next step
                    Text(navigationEngine.getDistanceText())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Instruction
                    Text(navigationEngine.getCurrentInstruction())
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
            
            // Next step preview
            if let nextStep = navigationEngine.navigationState.nextStep {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Then \(nextStep.plainInstruction)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(
            LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        .shadow(radius: 10)
    }
    
    // MARK: - Stats Bar
    
    private var statsBar: some View {
        HStack(spacing: 20) {
            // Remaining distance
            VStack(spacing: 4) {
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                Text(navigationEngine.getRemainingDistanceText())
                    .font(.headline)
                Text("Distance")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            // Remaining time
            VStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                Text(navigationEngine.getRemainingDurationText())
                    .font(.headline)
                Text("Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            // ETA
            VStack(spacing: 4) {
                Image(systemName: "flag.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                Text(navigationEngine.getETAText())
                    .font(.headline)
                Text("ETA")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
    }
    
    // MARK: - Exit Button
    
    private var exitButton: some View {
        Button(action: {
            showingExitConfirmation = true
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
    
    // MARK: - Navigation Control
    
    private func startNavigation() {
        print("🚗 DEBUG: Starting navigation")
        isNavigating = true
        
        // Set up location updates
        locationManager.setLocationUpdateHandler { location in
            navigationEngine.updateLocation(location)
        }
        locationManager.startUpdatingLocation()
        
        // Set up navigation callbacks
        navigationEngine.onInstructionUpdate = { instruction, distance in
            voiceGuidance.announce(instruction: instruction, distance: distance)
        }
        
        navigationEngine.onStepCompleted = {
            print("✅ DEBUG: Step completed")
        }
        
        navigationEngine.onNavigationCompleted = {
            print("🏁 DEBUG: Navigation completed!")
            voiceGuidance.announceArrival()
            stopNavigation()
            dismiss()
        }
        
        navigationEngine.onOffRoute = {
            print("⚠️ DEBUG: User went off route")
            voiceGuidance.announceOffRoute()
        }
        
        // Initial voice announcement
        let instruction = navigationEngine.getCurrentInstruction()
        voiceGuidance.announce(instruction: instruction, distance: 0)
    }
    
    private func stopNavigation() {
        print("🛑 DEBUG: Stopping navigation")
        isNavigating = false
        locationManager.stopUpdatingLocation()
        voiceGuidance.stopSpeaking()
    }
}

// MARK: - Navigation Map View

struct NavigationMapView: UIViewRepresentable {
    let navigationState: NavigationState
    let currentLocation: CLLocation?
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(
            withLatitude: 1.3521,
            longitude: 103.8198,
            zoom: 17
        )
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        
        // Navigation-specific settings
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = false
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = false
        mapView.settings.tiltGestures = false
        
        // Keep map oriented to user's heading
        mapView.settings.consumesGesturesInView = false
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Clear existing overlays
        mapView.clear()
        
        // Draw full route
        drawRoute(on: mapView)
        
        // Update camera to follow user
        if let location = currentLocation {
            let camera = GMSCameraPosition.camera(
                withLatitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                zoom: 17,
                bearing: location.course >= 0 ? location.course : 0,
                viewingAngle: 45
            )
            mapView.animate(to: camera)
        }
    }
    
    private func drawRoute(on mapView: GMSMapView) {
        let route = navigationState.route
        
        // Draw completed portion of route (in gray)
        for index in 0..<navigationState.currentStepIndex {
            let step = route.steps[index]
            if let path = GMSPath(fromEncodedPath: step.polyline) {
                let polyline = GMSPolyline(path: path)
                polyline.strokeWidth = 6
                polyline.strokeColor = .systemGray
                polyline.map = mapView
            }
        }
        
        // Draw remaining portion of route (in blue)
        for index in navigationState.currentStepIndex..<route.steps.count {
            let step = route.steps[index]
            if let path = GMSPath(fromEncodedPath: step.polyline) {
                let polyline = GMSPolyline(path: path)
                polyline.strokeWidth = 6
                polyline.strokeColor = .systemBlue
                polyline.map = mapView
            }
        }
        
        // Add destination marker
        if let lastStep = route.steps.last {
            let marker = GMSMarker()
            marker.position = lastStep.endLocation.clCoordinate
            marker.title = "Destination"
            marker.icon = GMSMarker.markerImage(with: .red)
            marker.map = mapView
        }
        
        // Highlight upcoming turn
        let nextTurnIndex = navigationState.currentStepIndex + 1
        if nextTurnIndex < route.steps.count {
            let nextStep = route.steps[nextTurnIndex]
            let marker = GMSMarker()
            marker.position = nextStep.startLocation.clCoordinate
            marker.icon = GMSMarker.markerImage(with: .orange)
            marker.map = mapView
        }
    }
}

// MARK: - Preview

struct ActiveNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRoute = Route(
            summary: "Sample Route",
            distance: Distance(meters: 5200, text: "5.2 km"),
            duration: Duration(seconds: 900, text: "15 mins"),
            steps: [],
            polyline: "",
            bounds: RouteBounds(
                northeast: Coordinate(latitude: 1.3, longitude: 103.9),
                southwest: Coordinate(latitude: 1.2, longitude: 103.8)
            )
        )
        
        ActiveNavigationView(route: sampleRoute, locationManager: LocationManager())
    }
}

