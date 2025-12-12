import SwiftUI
import CoreLocation

/// View for searching and selecting a destination
struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationManager: LocationManager
    @State private var placesService: PlacesService
    
    @State private var searchText = ""
    @State private var searchResults: [PlaceResult] = []
    @State private var isSearching = false
    @State private var selectedPlace: PlaceDetails?
    
    var onDestinationSelected: (PlaceDetails) -> Void
    
    // Sample destinations for Singapore
    private let suggestedDestinations = [
        ("Marina Bay Sands", CLLocationCoordinate2D(latitude: 1.2840, longitude: 103.8607)),
        ("Changi Airport", CLLocationCoordinate2D(latitude: 1.3644, longitude: 103.9915)),
        ("Sentosa", CLLocationCoordinate2D(latitude: 1.2494, longitude: 103.8303)),
        ("Orchard Road", CLLocationCoordinate2D(latitude: 1.3048, longitude: 103.8318)),
        ("Gardens by the Bay", CLLocationCoordinate2D(latitude: 1.2816, longitude: 103.8636)),
        ("Universal Studios", CLLocationCoordinate2D(latitude: 1.2540, longitude: 103.8238))
    ]
    
    init(locationManager: LocationManager, onDestinationSelected: @escaping (PlaceDetails) -> Void) {
        self.locationManager = locationManager
        self.onDestinationSelected = onDestinationSelected
        
        // Get API key from environment or plist
        let apiKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"] 
            ?? Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String 
            ?? ""
        _placesService = State(initialValue: PlacesService(apiKey: apiKey))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Search results or suggestions
                ScrollView {
                    if searchText.isEmpty {
                        suggestedDestinationsSection
                    } else if isSearching {
                        ProgressView("Searching...")
                            .padding()
                    } else if searchResults.isEmpty {
                        noResultsView
                    } else {
                        searchResultsSection
                    }
                }
            }
            .navigationTitle("Where to?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search for a place", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onChange(of: searchText) { newValue in
                    performSearch(query: newValue)
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(10)
        .padding()
    }
    
    // MARK: - Suggested Destinations
    
    private var suggestedDestinationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Destinations")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            ForEach(suggestedDestinations, id: \.0) { destination in
                Button(action: {
                    selectSuggestedDestination(name: destination.0, coordinate: destination.1)
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(destination.0)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text("Singapore")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                }
            }
            .listRowInsets(EdgeInsets())
        }
    }
    
    // MARK: - Search Results
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(searchResults.count) results")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top)
            
            ForEach(searchResults) { result in
                Button(action: {
                    selectSearchResult(result)
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "mappin.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.name)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text(result.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                
                Divider()
                    .padding(.leading, 60)
            }
        }
    }
    
    // MARK: - No Results View
    
    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No results found")
                .font(.headline)
            
            Text("Try a different search term")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func performSearch(query: String) {
        // Debounce search to avoid too many API calls
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task {
            // Small delay to debounce
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            // Check if query is still the same
            guard query == searchText else { return }
            
            do {
                let results = try await placesService.searchPlaces(
                    query: query,
                    location: locationManager.currentLocation?.coordinate
                )
                
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.searchResults = []
                    self.isSearching = false
                    print("❌ ERROR: Search failed - \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func selectSearchResult(_ result: PlaceResult) {
        print("🔍 DEBUG: Selected search result - \(result.name)")
        isSearching = true
        
        Task {
            do {
                let details = try await placesService.getPlaceDetails(placeId: result.placeId)
                
                await MainActor.run {
                    self.isSearching = false
                    onDestinationSelected(details)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isSearching = false
                    print("❌ ERROR: Failed to get place details - \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func selectSuggestedDestination(name: String, coordinate: CLLocationCoordinate2D) {
        print("🔍 DEBUG: Selected suggested destination - \(name)")
        let details = PlaceDetails(
            placeId: "suggested_\(name)",
            name: name,
            address: "Singapore",
            coordinate: coordinate
        )
        onDestinationSelected(details)
        dismiss()
    }
}

// MARK: - Preview

struct LocationSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchView(locationManager: LocationManager()) { _ in }
    }
}

