import Foundation
import CoreLocation

class TestDataGenerator {
    static let shared = TestDataGenerator()
    private let supabaseService = SupabaseService.shared
    
    func generateTestEvents(near location: CLLocation? = nil) async {
        // Default to San Francisco if no location provided
        let baseLocation = location ?? CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        // Use a valid UUID instead of "system"
        let systemUserId = UUID().uuidString
        print("Using system user ID: \(systemUserId)")
        
        // Create events within ~5km of the base location
        let events = [
            createEvent(
                name: "Beach Party",
                description: "Join us for a fun day at the beach with music and games!",
                location: "Sunny Beach",
                coordinate: randomCoordinate(near: baseLocation, maxDistance: 5000),
                startTime: Date().addingTimeInterval(3600 * 24 * 2), // 2 days from now
                duration: 3600 * 4, // 4 hours
                createdBy: systemUserId
            ),
            createEvent(
                name: "Tech Meetup",
                description: "Network with local developers and tech enthusiasts",
                location: "Downtown Coworking Space",
                coordinate: randomCoordinate(near: baseLocation, maxDistance: 3000),
                startTime: Date().addingTimeInterval(3600 * 24 * 3), // 3 days from now
                duration: 3600 * 2, // 2 hours
                createdBy: systemUserId
            ),
            createEvent(
                name: "Photography Workshop",
                description: "Learn portrait photography techniques from professionals",
                location: "City Park",
                coordinate: randomCoordinate(near: baseLocation, maxDistance: 4000),
                startTime: Date().addingTimeInterval(3600 * 24 * 1), // Tomorrow
                duration: 3600 * 3, // 3 hours
                createdBy: systemUserId
            ),
            createEvent(
                name: "Outdoor Yoga",
                description: "Relaxing yoga session in the park - all levels welcome",
                location: "Green Park",
                coordinate: randomCoordinate(near: baseLocation, maxDistance: 2000),
                startTime: Date().addingTimeInterval(3600 * 24 * 4 + 3600 * 10), // 4 days from now, morning
                duration: 3600 * 1.5, // 1.5 hours
                createdBy: systemUserId
            ),
            createEvent(
                name: "Food Festival",
                description: "Sample delicious food from local restaurants and food trucks",
                location: "Main Square",
                coordinate: randomCoordinate(near: baseLocation, maxDistance: 1500),
                startTime: Date().addingTimeInterval(3600 * 24 * 5), // 5 days from now
                duration: 3600 * 8, // 8 hours
                createdBy: systemUserId
            )
        ]
        
        // Upload events to Supabase
        for event in events {
            do {
                let _ = try await supabaseService.createEvent(event: event)
                print("Created event: \(event.name)")
            } catch {
                print("Failed to create event \(event.name): \(error.localizedDescription)")
            }
        }
    }
    
    private func createEvent(name: String, description: String, location: String, coordinate: CLLocationCoordinate2D, startTime: Date, duration: TimeInterval, createdBy: String) -> Event {
        return Event(
            id: UUID().uuidString,
            name: name,
            description: description,
            location: location,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(duration),
            createdBy: createdBy,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func randomCoordinate(near location: CLLocation, maxDistance: Double) -> CLLocationCoordinate2D {
        // Convert meters to degrees (rough approximation)
        let metersPerLatDegree = 111320.0 // at equator
        let metersPerLngDegree = cos(location.coordinate.latitude * .pi / 180.0) * 111320.0
        
        // Random distance in meters (up to maxDistance)
        let distanceMeters = Double.random(in: 100...maxDistance)
        
        // Random angle in radians
        let angle = Double.random(in: 0...(2 * .pi))
        
        // Calculate offsets
        let latOffset = (distanceMeters * cos(angle)) / metersPerLatDegree
        let lngOffset = (distanceMeters * sin(angle)) / metersPerLngDegree
        
        // Create new coordinate
        return CLLocationCoordinate2D(
            latitude: location.coordinate.latitude + latOffset,
            longitude: location.coordinate.longitude + lngOffset
        )
    }
} 