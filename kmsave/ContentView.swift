import SwiftUI
import CoreLocation

/// Home screen with full-screen map and search interface
struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var currentSpeed: Double = 0
    @State private var showingLocationSearch = false
    @State private var selectedTab = 0
    @State private var startLocation: String = ""
    @State private var endLocation: String = ""
    @State private var isSearchingStart = false
    @State private var isSearchingEnd = false
    @State private var selectedDestination: PlaceDetails?
    
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
            
            // Top search fields
            VStack {
                searchFieldsOverlay
                Spacer()
            }
            
            // Speed indicator (bottom left)
            VStack {
                Spacer()
                HStack {
                    speedIndicator
                    Spacer()
                }
            }
            
            // Navigation button (bottom right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    navigationButton
                }
            }
            
            // Bottom tab bar
            VStack {
                Spacer()
                bottomTabBar
            }
        }
        .sheet(isPresented: $showingLocationSearch) {
            if isSearchingEnd {
                LocationSearchView(locationManager: locationManager) { placeDetails in
                    endLocation = placeDetails.name
                    selectedDestination = placeDetails
                }
            }
        }
    }
    
    // MARK: - Search Fields Overlay
    
    private var searchFieldsOverlay: some View {
        VStack(spacing: 0) {
            // App name/logo
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("TONGA ROOM &")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            // Start location field
            HStack(spacing: 12) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                
                Text(startLocation.isEmpty ? "Start location" : startLocation)
                    .font(.system(size: 17))
                    .foregroundColor(startLocation.isEmpty ? .gray : .primary)
                
                Spacer()
                
                Button(action: {
                    // Navigate to current location
                }) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.leading, 44)
            
            // End location field
            HStack(spacing: 12) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                
                Button(action: {
                    isSearchingEnd = true
                    showingLocationSearch = true
                }) {
                    Text(endLocation.isEmpty ? "End location" : endLocation)
                        .font(.system(size: 17))
                        .foregroundColor(endLocation.isEmpty ? .gray : .primary)
                }
                
                Spacer()
                
                if !endLocation.isEmpty {
                    Button(action: {
                        endLocation = ""
                        selectedDestination = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .padding(.horizontal, 8)
        .padding(.top, 8)
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
        .padding(.bottom, 100)
        .onChange(of: locationManager.currentLocation) { newLocation in
            if let location = newLocation, location.speed >= 0 {
                // Convert m/s to km/h
                currentSpeed = location.speed * 3.6
            }
        }
    }
    
    // MARK: - Navigation Button
    
    private var navigationButton: some View {
        Button(action: {
            if let destination = selectedDestination {
                // Start navigation
                startNavigation(to: destination)
            }
        }) {
            Image(systemName: "location.fill")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(endLocation.isEmpty ? Color.gray : Color.blue)
                )
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
        .disabled(endLocation.isEmpty)
        .padding(.trailing, 20)
        .padding(.bottom, 100)
    }
    
    // MARK: - Bottom Tab Bar
    
    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            // Home tab
            TabBarButton(
                icon: "map.fill",
                title: "Home",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            // Plan Trip tab
            TabBarButton(
                icon: "location.north.fill",
                title: "Plan Trip",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
            
            // Spending tab
            TabBarButton(
                icon: "dollarsign.circle.fill",
                title: "Spending",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
            
            // Settings tab
            TabBarButton(
                icon: "gearshape.fill",
                title: "Settings",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
            }
        }
        .padding(.top, 8)
        .background(
            Color(uiColor: .systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
    }
    
    // MARK: - Helper Methods
    
    private func startNavigation(to destination: PlaceDetails) {
        print("🧭 Starting navigation to \(destination.name)")
        // This will be implemented when we integrate with RouteSelectionView
    }
}

// MARK: - Tab Bar Button

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                
                Text(title)
                    .font(.system(size: 11))
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
