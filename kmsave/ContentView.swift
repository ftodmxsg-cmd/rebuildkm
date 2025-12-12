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
            // App name/current location
            HStack(spacing: 8) {
                // Orange circle with user icon
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Text("TONGA ROOM &")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Start location field
            HStack(spacing: 12) {
                // Blue filled circle
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .padding(.leading, 4)
                
                Text(startLocation.isEmpty ? "Start location" : startLocation)
                    .font(.system(size: 17))
                    .foregroundColor(startLocation.isEmpty ? Color(uiColor: .placeholderText) : .primary)
                
                Spacer()
                
                // Navigation arrow button
                Button(action: {
                    // Use current location as start
                    if let location = locationManager.currentLocation {
                        startLocation = "Current location"
                    }
                }) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(uiColor: .systemBackground))
            
            // Divider line
            Rectangle()
                .fill(Color(uiColor: .separator).opacity(0.5))
                .frame(height: 0.5)
                .padding(.leading, 44)
            
            // End location field
            HStack(spacing: 12) {
                // Red filled circle
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .padding(.leading, 4)
                
                Button(action: {
                    isSearchingEnd = true
                    showingLocationSearch = true
                }) {
                    HStack {
                        Text(endLocation.isEmpty ? "End location" : endLocation)
                            .font(.system(size: 17))
                            .foregroundColor(endLocation.isEmpty ? Color(uiColor: .placeholderText) : .primary)
                        Spacer()
                    }
                }
                
                // Clear button (X in circle)
                if !endLocation.isEmpty {
                    Button(action: {
                        endLocation = ""
                        selectedDestination = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(uiColor: .systemBackground))
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
    
    // MARK: - Speed Indicator
    
    private var speedIndicator: some View {
        VStack(spacing: 2) {
            Text("\(Int(currentSpeed))")
                .font(.system(size: 44, weight: .regular))
                .foregroundColor(.white)
            
            Text("km/h")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(width: 90, height: 90)
        .background(
            Circle()
                .fill(Color.black.opacity(0.75))
        )
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .padding(.leading, 16)
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
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(endLocation.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        }
        .disabled(endLocation.isEmpty)
        .padding(.trailing, 16)
        .padding(.bottom, 100)
    }
    
    // MARK: - Bottom Tab Bar
    
    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            // Home tab - Map icon
            TabBarButton(
                icon: "map.fill",
                title: "Home",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            // Plan Trip tab - Compass/navigation icon
            TabBarButton(
                icon: "location.north.fill",
                title: "Plan Trip",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
            
            // Spending tab - Dollar sign
            TabBarButton(
                icon: "dollarsign.circle.fill",
                title: "Spending",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
            
            // Settings tab - Gear icon
            TabBarButton(
                icon: "gearshape.fill",
                title: "Settings",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
            }
        }
        .frame(height: 60)
        .background(
            Color(uiColor: .systemBackground)
                .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
        )
        .edgesIgnoringSafeArea(.bottom)
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
                    .font(.system(size: 22, weight: .medium))
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? .blue : Color(uiColor: .secondaryLabel))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
