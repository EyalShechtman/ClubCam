import SwiftUI
import MapKit
import CoreLocation

struct EventsListView: View {
    @EnvironmentObject var eventsViewModel: EventsViewModel
    @State private var showingMap = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // Toggle between Your Events and Join Events
                Picker("Events Type", selection: $eventsViewModel.isShowingUserEvents) {
                    Text("Join Events").tag(false)
                    Text("Your Events").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: eventsViewModel.isShowingUserEvents) { _ in
                    eventsViewModel.fetchEvents()
                }
                
                // Header with search bar
                HStack {
                    Text(eventsViewModel.isShowingUserEvents ? "Your Events" : "Events Near You")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    TextField("Search", text: $eventsViewModel.searchText)
                        .padding(7)
                        .padding(.horizontal, 25)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 8)
                                
                                if !eventsViewModel.searchText.isEmpty {
                                    Button(action: {
                                        eventsViewModel.searchText = ""
                                    }) {
                                        Image(systemName: "multiply.circle.fill")
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 8)
                                    }
                                }
                            }
                        )
                        .frame(width: 150)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Map/List toggle button
                Button(action: {
                    showingMap.toggle()
                }) {
                    HStack {
                        Image(systemName: showingMap ? "list.bullet" : "map")
                        Text(showingMap ? "Show List" : "Show Map")
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Content based on toggle
                if showingMap {
                    EventMapView(events: eventsViewModel.filteredEvents)
                        .cornerRadius(12)
                        .padding(.horizontal)
                } else {
                    if eventsViewModel.isLoading {
                        ProgressView("Loading events...")
                            .padding()
                    } else if let errorMessage = eventsViewModel.errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                                .padding()
                            
                            Text(errorMessage)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            Button("Try Again") {
                                eventsViewModel.fetchEvents()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding()
                    } else if eventsViewModel.filteredEvents.isEmpty {
                        VStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text(eventsViewModel.isShowingUserEvents ? 
                                 "You haven't joined any events yet." : 
                                 "No events found nearby.")
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(eventsViewModel.filteredEvents) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventRowView(event: event)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
                
                Spacer()
            }
            .navigationTitle("ClubCam Events")
            .navigationBarItems(trailing: Button(action: {
                eventsViewModel.fetchEvents()
            }) {
                Image(systemName: "arrow.clockwise")
            })
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Add Test Events") {
                            Task {
                                await TestDataGenerator.shared.generateTestEvents(
                                    near: eventsViewModel.currentLocation
                                )
                                await eventsViewModel.fetchEvents()
                            }
                        }
                        
                        Button("Use Default Location") {
                            eventsViewModel.currentLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
                            eventsViewModel.fetchEvents()
                        }
                        
                        Button("Print Current Location") {
                            if let location = eventsViewModel.currentLocation {
                                print("Current location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                            } else {
                                print("No current location available")
                            }
                        }
                        
                        Button("Test Database Connection") {
                            Task {
                                do {
                                    let testEvent = Event(
                                        id: UUID().uuidString,
                                        name: "Test Event",
                                        description: "Test Description",
                                        location: "Test Location",
                                        latitude: 37.7749,
                                        longitude: -122.4194,
                                        startTime: Date(),
                                        endTime: Date().addingTimeInterval(3600),
                                        createdBy: UUID().uuidString,
                                        createdAt: Date(),
                                        updatedAt: Date()
                                    )
                                    
                                    let service = SupabaseService.shared
                                    let _ = try await service.createEvent(event: testEvent)
                                    print("Successfully created test event")
                                } catch {
                                    print("Failed to create test event: \(error)")
                                }
                            }
                        }
                        
                        Button("Use Current Location") {
                            // Request location with high accuracy
                            eventsViewModel.requestPreciseLocation()
                        }
                    } label: {
                        Image(systemName: "wrench.and.screwdriver")
                    }
                }
            }
            .onAppear {
                // Use default location if needed
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    eventsViewModel.useDefaultLocationIfNeeded()
                }
            }
        }
    }
}

struct EventRowView: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text(event.name)
                    .font(.headline)
                
                Text(event.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text(formattedDate(event.startTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                // Join event action will be handled in the detail view
            }) {
                Text("View")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EventsListView_Previews: PreviewProvider {
    static var previews: some View {
        EventsListView()
            .environmentObject(EventsViewModel())
    }
} 
