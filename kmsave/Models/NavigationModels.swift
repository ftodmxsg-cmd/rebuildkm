import Foundation
import CoreLocation
import GoogleMaps

// MARK: - Route Model

/// Represents a complete route from origin to destination
struct Route: Identifiable, Codable {
    let id: UUID
    let summary: String
    let distance: Distance
    let duration: Duration
    let steps: [NavigationStep]
    let polyline: String // Encoded polyline
    let bounds: RouteBounds
    let warnings: [String]
    
    init(id: UUID = UUID(), summary: String, distance: Distance, duration: Duration, 
         steps: [NavigationStep], polyline: String, bounds: RouteBounds, warnings: [String] = []) {
        self.id = id
        self.summary = summary
        self.distance = distance
        self.duration = duration
        self.steps = steps
        self.polyline = polyline
        self.bounds = bounds
        self.warnings = warnings
    }
    
    /// Get decoded coordinates from polyline
    func getCoordinates() -> [CLLocationCoordinate2D] {
        return GMSPath(fromEncodedPath: polyline)?.coordinates() ?? []
    }
}

// MARK: - Navigation Step

/// Represents a single step in the navigation (e.g., "Turn left on Main St")
struct NavigationStep: Identifiable, Codable {
    let id: UUID
    let instruction: String // HTML formatted instruction
    let maneuver: ManeuverType
    let distance: Distance
    let duration: Duration
    let startLocation: Coordinate
    let endLocation: Coordinate
    let polyline: String
    
    init(id: UUID = UUID(), instruction: String, maneuver: ManeuverType, 
         distance: Distance, duration: Duration, startLocation: Coordinate, 
         endLocation: Coordinate, polyline: String) {
        self.id = id
        self.instruction = instruction
        self.maneuver = maneuver
        self.distance = distance
        self.duration = duration
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.polyline = polyline
    }
    
    /// Get plain text instruction (removes HTML tags)
    var plainInstruction: String {
        instruction.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

// MARK: - Maneuver Type

/// Types of navigation maneuvers
enum ManeuverType: String, Codable {
    case turnLeft = "turn-left"
    case turnRight = "turn-right"
    case turnSlightLeft = "turn-slight-left"
    case turnSlightRight = "turn-slight-right"
    case turnSharpLeft = "turn-sharp-left"
    case turnSharpRight = "turn-sharp-right"
    case uturnLeft = "uturn-left"
    case uturnRight = "uturn-right"
    case merge = "merge"
    case straight = "straight"
    case rampLeft = "ramp-left"
    case rampRight = "ramp-right"
    case fork = "fork"
    case roundaboutLeft = "roundabout-left"
    case roundaboutRight = "roundabout-right"
    case ferry = "ferry"
    case ferryTrain = "ferry-train"
    case keep = "keep"
    case unknown = ""
    
    /// Get icon name for the maneuver
    var iconName: String {
        switch self {
        case .turnLeft, .turnSlightLeft: return "arrow.turn.up.left"
        case .turnRight, .turnSlightRight: return "arrow.turn.up.right"
        case .turnSharpLeft: return "arrow.uturn.left"
        case .turnSharpRight: return "arrow.uturn.right"
        case .uturnLeft, .uturnRight: return "arrow.uturn.backward"
        case .merge: return "arrow.triangle.merge"
        case .straight, .keep: return "arrow.up"
        case .rampLeft: return "arrow.turn.up.left"
        case .rampRight: return "arrow.turn.up.right"
        case .fork: return "arrow.triangle.branch"
        case .roundaboutLeft, .roundaboutRight: return "arrow.triangle.turn.up.right.circle"
        case .ferry, .ferryTrain: return "ferry"
        case .unknown: return "arrow.up"
        }
    }
}

// MARK: - Distance

/// Represents a distance with value and text
struct Distance: Codable {
    let meters: Int
    let text: String // "5.2 km" or "500 m"
    
    var kilometers: Double {
        Double(meters) / 1000.0
    }
    
    var formattedString: String {
        if meters < 1000 {
            return "\(meters) m"
        } else {
            return String(format: "%.1f km", kilometers)
        }
    }
}

// MARK: - Duration

/// Represents a time duration
struct Duration: Codable {
    let seconds: Int
    let text: String // "15 mins" or "1 hour 30 mins"
    
    var minutes: Int {
        seconds / 60
    }
    
    var formattedString: String {
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins) min"
        }
    }
}

// MARK: - Coordinate

/// Represents a geographical coordinate
struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double
    
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}

// MARK: - Route Bounds

/// Represents the bounding box of a route
struct RouteBounds: Codable {
    let northeast: Coordinate
    let southwest: Coordinate
    
    var gmsBounds: GMSCoordinateBounds {
        GMSCoordinateBounds(
            coordinate: northeast.clCoordinate,
            coordinate: southwest.clCoordinate
        )
    }
}

// MARK: - Navigation State

/// Represents the current state of active navigation
struct NavigationState {
    var route: Route
    var currentStepIndex: Int
    var distanceToNextStep: Distance
    var remainingDistance: Distance
    var remainingDuration: Duration
    var estimatedArrivalTime: Date
    var isOffRoute: Bool
    var lastAnnouncedDistance: Int? // Last distance at which we announced instruction
    
    init(route: Route) {
        self.route = route
        self.currentStepIndex = 0
        self.distanceToNextStep = route.steps.first?.distance ?? Distance(meters: 0, text: "0 m")
        self.remainingDistance = route.distance
        self.remainingDuration = route.duration
        self.estimatedArrivalTime = Date().addingTimeInterval(TimeInterval(route.duration.seconds))
        self.isOffRoute = false
        self.lastAnnouncedDistance = nil
    }
    
    var currentStep: NavigationStep? {
        guard currentStepIndex < route.steps.count else { return nil }
        return route.steps[currentStepIndex]
    }
    
    var nextStep: NavigationStep? {
        let nextIndex = currentStepIndex + 1
        guard nextIndex < route.steps.count else { return nil }
        return route.steps[nextIndex]
    }
    
    var isLastStep: Bool {
        currentStepIndex == route.steps.count - 1
    }
    
    var progressPercentage: Double {
        let totalMeters = Double(route.distance.meters)
        let remainingMeters = Double(remainingDistance.meters)
        guard totalMeters > 0 else { return 0 }
        return (totalMeters - remainingMeters) / totalMeters * 100
    }
    
    mutating func moveToNextStep() {
        guard !isLastStep else { return }
        currentStepIndex += 1
        lastAnnouncedDistance = nil
        print("🧭 DEBUG: Moving to step \(currentStepIndex + 1) of \(route.steps.count)")
    }
}
