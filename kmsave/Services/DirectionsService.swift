import Foundation
import CoreLocation

/// Service for fetching routes from Google Directions API
class DirectionsService {
    
    // MARK: - Properties
    private let apiKey: String
    private let baseURL = "https://maps.googleapis.com/maps/api/directions/json"
    
    // MARK: - Initialization
    init(apiKey: String) {
        self.apiKey = apiKey
        print("🗺️ DEBUG: DirectionsService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Fetch route from origin to destination
    func fetchRoute(from origin: CLLocationCoordinate2D, 
                   to destination: CLLocationCoordinate2D,
                   mode: TravelMode = .driving) async throws -> Route {
        
        print("🗺️ DEBUG: Fetching route from (\(origin.latitude), \(origin.longitude)) to (\(destination.latitude), \(destination.longitude))")
        
        // Build URL with parameters
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "origin", value: "\(origin.latitude),\(origin.longitude)"),
            URLQueryItem(name: "destination", value: "\(destination.latitude),\(destination.longitude)"),
            URLQueryItem(name: "mode", value: mode.rawValue),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "alternatives", value: "false"), // Single route for now
            URLQueryItem(name: "units", value: "metric")
        ]
        
        guard let url = components.url else {
            throw DirectionsError.invalidURL
        }
        
        // Make API request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DirectionsError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ ERROR: HTTP status code \(httpResponse.statusCode)")
            throw DirectionsError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse JSON response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let directionsResponse = try decoder.decode(DirectionsResponse.self, from: data)
        
        // Check API status
        guard directionsResponse.status == "OK" else {
            print("❌ ERROR: Directions API returned status: \(directionsResponse.status)")
            throw DirectionsError.apiError(status: directionsResponse.status)
        }
        
        // Get first route
        guard let routeData = directionsResponse.routes.first else {
            throw DirectionsError.noRouteFound
        }
        
        // Parse route into our model
        let route = try parseRoute(from: routeData)
        
        print("✅ DEBUG: Route fetched successfully - \(route.distance.text), \(route.duration.text)")
        return route
    }
    
    // MARK: - Private Methods
    
    private func parseRoute(from routeData: DirectionsRoute) throws -> Route {
        guard let leg = routeData.legs.first else {
            throw DirectionsError.invalidRouteData
        }
        
        // Parse steps
        let steps = leg.steps.map { stepData -> NavigationStep in
            NavigationStep(
                instruction: stepData.htmlInstructions,
                maneuver: ManeuverType(rawValue: stepData.maneuver ?? "") ?? .unknown,
                distance: Distance(meters: stepData.distance.value, text: stepData.distance.text),
                duration: Duration(seconds: stepData.duration.value, text: stepData.duration.text),
                startLocation: Coordinate(
                    latitude: stepData.startLocation.lat,
                    longitude: stepData.startLocation.lng
                ),
                endLocation: Coordinate(
                    latitude: stepData.endLocation.lat,
                    longitude: stepData.endLocation.lng
                ),
                polyline: stepData.polyline.points
            )
        }
        
        // Create route
        let route = Route(
            summary: routeData.summary,
            distance: Distance(meters: leg.distance.value, text: leg.distance.text),
            duration: Duration(seconds: leg.duration.value, text: leg.duration.text),
            steps: steps,
            polyline: routeData.overviewPolyline.points,
            bounds: RouteBounds(
                northeast: Coordinate(
                    latitude: routeData.bounds.northeast.lat,
                    longitude: routeData.bounds.northeast.lng
                ),
                southwest: Coordinate(
                    latitude: routeData.bounds.southwest.lat,
                    longitude: routeData.bounds.southwest.lng
                )
            ),
            warnings: routeData.warnings
        )
        
        return route
    }
}

// MARK: - Travel Mode

enum TravelMode: String {
    case driving
    case walking
    case bicycling
    case transit
}

// MARK: - Directions Error

enum DirectionsError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case apiError(status: String)
    case noRouteFound
    case invalidRouteData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for directions request"
        case .invalidResponse:
            return "Invalid response from directions API"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .apiError(let status):
            return "Directions API error: \(status)"
        case .noRouteFound:
            return "No route found between the locations"
        case .invalidRouteData:
            return "Invalid route data received"
        }
    }
}

// MARK: - API Response Models

private struct DirectionsResponse: Decodable {
    let routes: [DirectionsRoute]
    let status: String
}

private struct DirectionsRoute: Decodable {
    let summary: String
    let legs: [RouteLeg]
    let overviewPolyline: PolylineData
    let bounds: BoundsData
    let warnings: [String]
    
    enum CodingKeys: String, CodingKey {
        case summary, legs, bounds, warnings
        case overviewPolyline = "overview_polyline"
    }
}

private struct RouteLeg: Decodable {
    let distance: DistanceData
    let duration: DurationData
    let steps: [StepData]
}

private struct StepData: Decodable {
    let htmlInstructions: String
    let distance: DistanceData
    let duration: DurationData
    let startLocation: LocationData
    let endLocation: LocationData
    let polyline: PolylineData
    let maneuver: String?
    
    enum CodingKeys: String, CodingKey {
        case distance, duration, polyline, maneuver
        case htmlInstructions = "html_instructions"
        case startLocation = "start_location"
        case endLocation = "end_location"
    }
}

private struct DistanceData: Decodable {
    let text: String
    let value: Int
}

private struct DurationData: Decodable {
    let text: String
    let value: Int
}

private struct LocationData: Decodable {
    let lat: Double
    let lng: Double
}

private struct PolylineData: Decodable {
    let points: String
}

private struct BoundsData: Decodable {
    let northeast: LocationData
    let southwest: LocationData
}
