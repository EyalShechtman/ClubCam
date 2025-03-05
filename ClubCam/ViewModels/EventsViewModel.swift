import Foundation
import Combine
import CoreLocation

class EventsViewModel: NSObject, ObservableObject {
    @Published var nearbyEvents: [Event] = []
    @Published var userEvents: [Event] = []
    @Published var selectedEvent: Event?
    @Published var isShowingUserEvents = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    
    private let supabaseService = SupabaseService.shared
    private let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // Less battery usage
        locationManager.distanceFilter = 100 // Only update when moved 100 meters
        
        // Check authorization status immediately
        checkLocationAuthorization()
    }
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            print("Location authorization granted")
        case .denied, .restricted:
            self.errorMessage = "Location access denied. Please enable in Settings."
            print("Location authorization denied")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            print("Location authorization not determined")
        @unknown default:
            break
        }
    }
    
    // Add a fallback method to use a default location
    func useDefaultLocationIfNeeded() {
        if currentLocation == nil {
            // Use San Francisco as default
            currentLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
            print("Using default location: San Francisco")
            fetchEvents()
        }
    }
    
    func fetchEvents() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        Task {
            do {
                if isShowingUserEvents {
                    let events = try await supabaseService.fetchUserEvents()
                    DispatchQueue.main.async {
                        self.userEvents = events
                        self.isLoading = false
                    }
                } else if let location = currentLocation {
                    let events = try await supabaseService.fetchNearbyEvents(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                    DispatchQueue.main.async {
                        self.nearbyEvents = events
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Location not available. Please enable location services."
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func joinEvent(eventId: String) async throws {
        // First check if the user has already joined
        let hasJoined = try await supabaseService.hasUserJoinedEvent(eventId: eventId)
        
        if hasJoined {
            throw NSError(domain: "EventsViewModel", code: 1001, userInfo: [NSLocalizedDescriptionKey: "You've already joined this event"])
        }
        
        // If not joined, proceed with joining
        try await supabaseService.joinEvent(eventId: eventId)
        
        // Refresh events after joining
        await fetchEvents()
    }
    
    var filteredEvents: [Event] {
        let events = isShowingUserEvents ? userEvents : nearbyEvents
        
        if searchText.isEmpty {
            return events
        } else {
            return events.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                (event.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                event.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func requestPreciseLocation() {
        // Request a one-time precise location update
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()
        print("Requesting precise location...")
    }
}

extension EventsViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Only update if location has changed significantly
        if currentLocation == nil || currentLocation!.distance(from: location) > 100 {
            currentLocation = location
            fetchEvents()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Failed to get your location: \(error.localizedDescription)"
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.errorMessage = "Location access denied. Please enable in Settings."
            }
        case .notDetermined:
            // Wait for user to make a choice
            break
        @unknown default:
            break
        }
    }
} 
