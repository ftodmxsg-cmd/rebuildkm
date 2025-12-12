import SwiftUI
import GoogleMaps

@main
struct kmsaveApp: App {
    
    init() {
        // Configure Google Maps SDK
        configureGoogleMaps()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureGoogleMaps() {
        print("🗺️ DEBUG: Configuring Google Maps SDK...")
        
        // Try to load API key from environment variable first
        if let apiKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"],
           !apiKey.isEmpty,
           apiKey != "YOUR_API_KEY_HERE" {
            GMSServices.provideAPIKey(apiKey)
            print("✅ SUCCESS: API key loaded from environment variable")
            print("🔑 API Key (first 10 chars): \(String(apiKey.prefix(10)))...")
            return
        }
        
        // Fallback: Try to load from Info.plist
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String,
           !apiKey.isEmpty,
           apiKey != "YOUR_API_KEY_HERE" {
            GMSServices.provideAPIKey(apiKey)
            print("✅ SUCCESS: API key loaded from Info.plist")
            print("🔑 API Key (first 10 chars): \(String(apiKey.prefix(10)))...")
            return
        }
        
        // No API key found
        print("❌ ERROR: No Google Maps API key found!")
        print("❌ Environment variable GOOGLE_MAPS_API_KEY: \(ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"] ?? "nil")")
        print("❌ Info.plist GoogleMapsAPIKey: \(Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String ?? "nil")")
        print("Please configure GOOGLE_MAPS_API_KEY in Xcode scheme or Secrets.xcconfig")
    }
}

