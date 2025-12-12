import Foundation
import CoreLocation

/// Service for searching places using Google Places API
class PlacesService {
    // MARK: - Properties
    private let apiKey: String
    private let autocompleteURL = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
    private let detailsURL = "https://maps.googleapis.com/maps/api/place/details/json"
    
    // MARK: - Initialization
    init(apiKey: String) {
        self.apiKey = apiKey
        print("🔍 DEBUG: PlacesService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Search for places using autocomplete
    func searchPlaces(query: String, location: CLLocationCoordinate2D?) async throws -> [PlaceResult] {
        guard !query.isEmpty else {
            return []
        }
        
        print("🔍 DEBUG: Searching for '\(query)'")
        
        // Build URL with parameters
        var components = URLComponents(string: autocompleteURL)!
        var queryItems = [
            URLQueryItem(name: "input", value: query),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "components", value: "country:sg"), // Restrict to Singapore
            URLQueryItem(name: "types", value: "establishment|geocode") // All types
        ]
        
        // Add location bias if available (prioritize nearby results)
        if let location = location {
            let locationBias = "\(location.latitude),\(location.longitude)"
            queryItems.append(URLQueryItem(name: "location", value: locationBias))
            queryItems.append(URLQueryItem(name: "radius", value: "50000")) // 50km radius
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw PlacesError.invalidURL
        }
        
        // Make API request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlacesError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ ERROR: HTTP status code \(httpResponse.statusCode)")
            throw PlacesError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse JSON response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let autocompleteResponse = try decoder.decode(AutocompleteResponse.self, from: data)
        
        // Check API status
        guard autocompleteResponse.status == "OK" || autocompleteResponse.status == "ZERO_RESULTS" else {
            print("❌ ERROR: Places API returned status: \(autocompleteResponse.status)")
            throw PlacesError.apiError(status: autocompleteResponse.status)
        }
        
        // Convert to PlaceResult
        let results = autocompleteResponse.predictions.map { prediction in
            PlaceResult(
                placeId: prediction.placeId,
                name: prediction.structuredFormatting.mainText,
                address: prediction.description
            )
        }
        
        print("✅ DEBUG: Found \(results.count) places for '\(query)'")
        return results
    }
    
    /// Get place details including coordinates
    func getPlaceDetails(placeId: String) async throws -> PlaceDetails {
        print("🔍 DEBUG: Fetching details for place ID: \(placeId)")
        
        // Build URL with parameters
        var components = URLComponents(string: detailsURL)!
        components.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "fields", value: "geometry,name,formatted_address"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw PlacesError.invalidURL
        }
        
        // Make API request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlacesError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ ERROR: HTTP status code \(httpResponse.statusCode)")
            throw PlacesError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse JSON response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let detailsResponse = try decoder.decode(PlaceDetailsResponse.self, from: data)
        
        // Check API status
        guard detailsResponse.status == "OK" else {
            print("❌ ERROR: Place Details API returned status: \(detailsResponse.status)")
            throw PlacesError.apiError(status: detailsResponse.status)
        }
        
        let result = detailsResponse.result
        let coordinate = CLLocationCoordinate2D(
            latitude: result.geometry.location.lat,
            longitude: result.geometry.location.lng
        )
        
        let placeDetails = PlaceDetails(
            placeId: placeId,
            name: result.name,
            address: result.formattedAddress ?? result.name,
            coordinate: coordinate
        )
        
        print("✅ DEBUG: Place details fetched - \(placeDetails.name)")
        return placeDetails
    }
}

// MARK: - Models

/// Search result from autocomplete
struct PlaceResult: Identifiable {
    let id = UUID()
    let placeId: String
    let name: String
    let address: String
}

/// Detailed place information with coordinates
struct PlaceDetails: Equatable {
    let placeId: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: PlaceDetails, rhs: PlaceDetails) -> Bool {
        lhs.placeId == rhs.placeId
    }
}

// MARK: - Errors

enum PlacesError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case apiError(status: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for places request"
        case .invalidResponse:
            return "Invalid response from places API"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .apiError(let status):
            return "Places API error: \(status)"
        }
    }
}

// MARK: - API Response Models

private struct AutocompleteResponse: Decodable {
    let predictions: [Prediction]
    let status: String
}

private struct Prediction: Decodable {
    let description: String
    let placeId: String
    let structuredFormatting: StructuredFormatting
}

private struct StructuredFormatting: Decodable {
    let mainText: String
    let secondaryText: String?
}

private struct PlaceDetailsResponse: Decodable {
    let result: PlaceDetailsResult
    let status: String
}

private struct PlaceDetailsResult: Decodable {
    let name: String
    let formattedAddress: String?
    let geometry: Geometry
}

private struct Geometry: Decodable {
    let location: LocationData
}

private struct LocationData: Decodable {
    let lat: Double
    let lng: Double
}

