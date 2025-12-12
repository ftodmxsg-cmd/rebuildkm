import SwiftUI
import GoogleMaps

struct MapView: View {
    @State private var isMapReady = false
    
    var body: some View {
        ZStack {
            GoogleMapView(isReady: $isMapReady)
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
    
    // Default location: Singapore (Marina Bay Sands)
    private let defaultLocation = CLLocationCoordinate2D(
        latitude: 1.2840,
        longitude: 103.8607
    )
    
    func makeUIView(context: Context) -> GMSMapView {
        // Create camera positioned at Singapore
        let camera = GMSCameraPosition.camera(
            withLatitude: defaultLocation.latitude,
            longitude: defaultLocation.longitude,
            zoom: 12.0
        )
        
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.delegate = context.coordinator
        
        // Map settings
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = true
        
        // Add a marker at default location
        let marker = GMSMarker()
        marker.position = defaultLocation
        marker.title = "Singapore"
        marker.snippet = "Marina Bay Sands"
        marker.map = mapView
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isReady = true
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // Update map if needed
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

