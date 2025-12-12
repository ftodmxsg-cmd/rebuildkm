import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showingRouteSelection = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("KM Save")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Navigation App for Singapore Drivers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Main action buttons
                VStack(spacing: 16) {
                    // Navigate button
                    Button(action: {
                        showingRouteSelection = true
                    }) {
                        HStack {
                            Image(systemName: "location.fill.viewfinder")
                            Text("Start Navigation")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Open Map button
                    NavigationLink(destination: MapView()) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("View Map")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingRouteSelection) {
            RouteSelectionView(locationManager: locationManager)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

