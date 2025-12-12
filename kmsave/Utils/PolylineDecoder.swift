import Foundation
import CoreLocation

/// Utility for decoding Google Maps encoded polylines
/// Rule 0: Simple decoder implementation based on Google's algorithm
struct PolylineDecoder {
    
    /// Decode an encoded polyline string into array of coordinates
    /// Algorithm from: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
    static func decode(_ encodedString: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = encodedString.startIndex
        var lat = 0
        var lng = 0
        
        while index < encodedString.endIndex {
            // Decode latitude
            var result = 0
            var shift = 0
            var byte: Int
            
            repeat {
                byte = Int(encodedString[index].asciiValue! - 63)
                index = encodedString.index(after: index)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20
            
            let deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            lat += deltaLat
            
            // Decode longitude
            result = 0
            shift = 0
            
            repeat {
                byte = Int(encodedString[index].asciiValue! - 63)
                index = encodedString.index(after: index)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20
            
            let deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            lng += deltaLng
            
            // Convert to actual coordinates
            let coordinate = CLLocationCoordinate2D(
                latitude: Double(lat) / 1e5,
                longitude: Double(lng) / 1e5
            )
            coordinates.append(coordinate)
        }
        
        return coordinates
    }
}

