import SwiftUI
import CoreLocation

/// Home screen with full-screen map and search interface (Waze-style)
struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showingRouteSelection = false
    @State private var currentSpeed: Double = 0
    
    var body: some View {
        ZStack {
            // Full-screen map
            MapView(
                route: nil,
                currentLocation: locationManager.currentLocation,
                showUserLocation: true
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                locationManager.requestLocationPermission()
                locationManager.startUpdatingLocation()
            }
            
            // Speed indicator (bottom left)
            VStack {
                Spacer()
                HStack {
                    speedIndicator
                    Spacer()
                }
                .padding(.bottom, 140)
            }
            
            // Search overlay (bottom)
            VStack {
                Spacer()
                searchOverlay
            }
        }
    }
    
    // MARK: - Speed Indicator
    
    private var speedIndicator: some View {
        VStack(spacing: 4) {
            Text("\(Int(currentSpeed))")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(.white)
            
            Text("km/h")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(width: 100, height: 100)
        .background(
            Circle()
                .fill(Color.black.opacity(0.7))
        )
        .padding(.leading, 20)
        .onChange(of: locationManager.currentLocation) { newLocation in
            if let location = newLocation, location.speed >= 0 {
                // Convert m/s to km/h
                currentSpeed = location.speed * 3.6
            }
        }
    }
    
    // MARK: - Search Overlay
    
    private var searchOverlay: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            // Search bar
            Button(action: {
                showingRouteSelection = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                    
                    Text("Where to?")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.red)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            // Quick action
            Button(action: {
                // Navigate home action
            }) {
                HStack {
                    Image(systemName: "house.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                    
                    Text("My Waze")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            Color(uiColor: .systemBackground)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
        .sheet(isPresented: $showingRouteSelection) {
            RouteSelectionView(locationManager: locationManager)
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
