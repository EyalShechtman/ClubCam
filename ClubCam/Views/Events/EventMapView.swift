import SwiftUI
import MapKit

struct EventMapView: View {
    let events: [Event]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedEvent: Event?
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: events) { event in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude)) {
                    Button(action: {
                        selectedEvent = event
                    }) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            
                            Text(event.name)
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(5)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(5)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            if let selectedEvent = selectedEvent {
                VStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(selectedEvent.name)
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                self.selectedEvent = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text(selectedEvent.location)
                            .font(.subheadline)
                        
                        if let description = selectedEvent.description {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(.black)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Spacer()
                            
                            NavigationLink(destination: EventDetailView(event: selectedEvent)) {
                                Text("View Details")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding()
                }
            }
        }
        .onAppear {
            updateRegion()
        }
    }
    
    private func updateRegion() {
        guard !events.isEmpty else { return }
        
        // Calculate the center point and appropriate zoom level
        let latitudes = events.map { $0.latitude }
        let longitudes = events.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.1, (maxLat - minLat) * 1.5),
            longitudeDelta: max(0.1, (maxLon - minLon) * 1.5)
        )
        
        region = MKCoordinateRegion(center: center, span: span)
    }
}

struct EventMapView_Previews: PreviewProvider {
    static var previews: some View {
        EventMapView(events: [
            Event(
                id: "1",
                name: "Beach Party",
                description: "Fun in the sun!",
                location: "Santa Monica Beach",
                latitude: 34.0195,
                longitude: -118.4912,
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600 * 3),
                createdBy: "user1",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Event(
                id: "2",
                name: "Downtown Concert",
                description: "Live music event",
                location: "Downtown LA",
                latitude: 34.0522,
                longitude: -118.2437,
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600 * 4),
                createdBy: "user2",
                createdAt: Date(),
                updatedAt: Date()
            )
        ])
    }
} 
