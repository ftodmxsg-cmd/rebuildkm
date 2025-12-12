import Foundation
import CoreLocation
import GoogleMaps
import Combine

/// Core navigation engine that tracks user progress and manages navigation state
class NavigationEngine: ObservableObject {
    // MARK: - Properties
    @Published var navigationState: NavigationState
    var onInstructionUpdate: ((String, Int) -> Void)?
    var onStepCompleted: (() -> Void)?
    var onNavigationCompleted: (() -> Void)?
    var onOffRoute: (() -> Void)?
    
    private let distanceThresholdToNextStep: Double = 50 // meters
    private let offRouteThreshold: Double = 50 // meters off route triggers rerouting
    
    // Distance thresholds for voice announcements
    private let announcementDistances = [500, 200, 100, 50] // meters
    
    // MARK: - Initialization
    init(route: Route) {
        self.navigationState = NavigationState(route: route)
        print("🧭 DEBUG: NavigationEngine initialized with route of \(route.steps.count) steps")
    }
    
    // MARK: - Public Methods
    
    /// Update navigation based on current location
    func updateLocation(_ location: CLLocation) {
        guard let currentStep = navigationState.currentStep else {
            // Navigation completed
            if !navigationState.isLastStep {
                print("⚠️ DEBUG: No current step available but not on last step")
            }
            return
        }
        
        // Calculate distance to end of current step
        let stepEndLocation = CLLocation(
            latitude: currentStep.endLocation.latitude,
            longitude: currentStep.endLocation.longitude
        )
        let distanceToStepEnd = location.distance(from: stepEndLocation)
        
        // Update distance to next step
        navigationState.distanceToNextStep = Distance(
            meters: Int(distanceToStepEnd),
            text: formatDistance(distanceToStepEnd)
        )
        
        // Calculate remaining distance and duration
        updateRemainingDistanceAndDuration(from: location)
        
        // Check if user completed current step
        if distanceToStepEnd < distanceThresholdToNextStep {
            handleStepCompletion()
        }
        
        // Check if announcement should be made
        checkForAnnouncement(distanceToStep: Int(distanceToStepEnd))
        
        // Check if user is off route
        checkIfOffRoute(location: location, currentStep: currentStep)
        
        print("🧭 DEBUG: Updated - Distance to next step: \(Int(distanceToStepEnd))m, Step \(navigationState.currentStepIndex + 1)/\(navigationState.route.steps.count)")
    }
    
    /// Force move to next step (useful for manual override)
    func moveToNextStep() {
        navigationState.moveToNextStep()
        onStepCompleted?()
        
        if navigationState.isLastStep {
            print("🏁 DEBUG: Reached final step!")
        }
    }
    
    /// Get formatted instruction for current step
    func getCurrentInstruction() -> String {
        guard let step = navigationState.currentStep else {
            return "Continue to destination"
        }
        return step.plainInstruction
    }
    
    /// Get distance text for current step
    func getDistanceText() -> String {
        return navigationState.distanceToNextStep.formattedString
    }
    
    /// Get ETA text
    func getETAText() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: navigationState.estimatedArrivalTime)
    }
    
    /// Get remaining distance text
    func getRemainingDistanceText() -> String {
        return navigationState.remainingDistance.formattedString
    }
    
    /// Get remaining duration text
    func getRemainingDurationText() -> String {
        return navigationState.remainingDuration.formattedString
    }
    
    // MARK: - Private Methods
    
    private func handleStepCompletion() {
        print("✅ DEBUG: Step \(navigationState.currentStepIndex + 1) completed")
        
        if navigationState.isLastStep {
            print("🏁 DEBUG: Navigation completed!")
            onNavigationCompleted?()
        } else {
            navigationState.moveToNextStep()
            onStepCompleted?()
            
            // Notify with new instruction
            if let newStep = navigationState.currentStep {
                let instruction = newStep.plainInstruction
                let distance = newStep.distance.meters
                onInstructionUpdate?(instruction, distance)
                print("🗣️ DEBUG: New instruction: \(instruction)")
            }
        }
    }
    
    private func checkForAnnouncement(distanceToStep: Int) {
        // Check if we should announce the instruction
        for threshold in announcementDistances {
            // If we're at this threshold and haven't announced at this distance yet
            if distanceToStep <= threshold && distanceToStep > threshold - 20 {
                if navigationState.lastAnnouncedDistance == nil || navigationState.lastAnnouncedDistance! > threshold {
                    // Make announcement
                    if let step = navigationState.currentStep {
                        let instruction = step.plainInstruction
                        onInstructionUpdate?(instruction, distanceToStep)
                        navigationState.lastAnnouncedDistance = threshold
                        print("🗣️ DEBUG: Announcement at \(threshold)m: \(instruction)")
                    }
                    break
                }
            }
        }
    }
    
    private func checkIfOffRoute(location: CLLocation, currentStep: NavigationStep) {
        // Get polyline coordinates for current step
        guard let path = GMSPath(fromEncodedPath: currentStep.polyline) else {
            return
        }
        
        let coordinates = path.coordinates()
        
        // Find minimum distance to route
        var minDistance = Double.infinity
        for coordinate in coordinates {
            let pointLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distance = location.distance(from: pointLocation)
            minDistance = min(minDistance, distance)
        }
        
        // Check if user is off route
        let wasOffRoute = navigationState.isOffRoute
        navigationState.isOffRoute = minDistance > offRouteThreshold
        
        // Trigger callback if just went off route
        if navigationState.isOffRoute && !wasOffRoute {
            print("⚠️ DEBUG: User went off route - \(Int(minDistance))m from route")
            onOffRoute?()
        } else if !navigationState.isOffRoute && wasOffRoute {
            print("✅ DEBUG: User back on route")
        }
    }
    
    private func updateRemainingDistanceAndDuration(from location: CLLocation) {
        // Calculate remaining distance
        var totalRemainingDistance = 0
        
        // Add distance to end of current step
        if let currentStep = navigationState.currentStep {
            let stepEndLocation = CLLocation(
                latitude: currentStep.endLocation.latitude,
                longitude: currentStep.endLocation.longitude
            )
            totalRemainingDistance += Int(location.distance(from: stepEndLocation))
        }
        
        // Add distance of remaining steps
        for index in (navigationState.currentStepIndex + 1)..<navigationState.route.steps.count {
            totalRemainingDistance += navigationState.route.steps[index].distance.meters
        }
        
        navigationState.remainingDistance = Distance(
            meters: totalRemainingDistance,
            text: formatDistance(Double(totalRemainingDistance))
        )
        
        // Estimate remaining duration based on average speed
        // Assuming average speed of 50 km/h for cars
        let averageSpeedMPS = 50.0 / 3.6 // 50 km/h in meters per second
        let estimatedSeconds = Int(Double(totalRemainingDistance) / averageSpeedMPS)
        
        navigationState.remainingDuration = Duration(
            seconds: estimatedSeconds,
            text: formatDuration(estimatedSeconds)
        )
        
        // Update ETA
        navigationState.estimatedArrivalTime = Date().addingTimeInterval(TimeInterval(estimatedSeconds))
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000.0)
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}

// MARK: - GMSPath Extension

extension GMSPath {
    /// Convert GMSPath to array of CLLocationCoordinate2D
    func coordinates() -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        for index in 0..<count() {
            coordinates.append(coordinate(at: index))
        }
        return coordinates
    }
}

