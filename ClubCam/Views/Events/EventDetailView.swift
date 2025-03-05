import SwiftUI
import CoreLocation

struct EventDetailView: View {
    let event: Event
    @StateObject private var photosViewModel = PhotosViewModel()
    @EnvironmentObject var eventsViewModel: EventsViewModel
    @State private var showingCamera = false
    @State private var showingJoinConfirmation = false
    @State private var hasJoined = false
    @State private var isJoining = false
    @State private var joinError: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Event details section
                VStack(alignment: .leading, spacing: 10) {
                    Text(event.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.red)
                        Text(event.location)
                            .font(.headline)
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text(formattedDate(event.startTime))
                            .font(.subheadline)
                    }
                    
                    if let description = event.description {
                        Text(description)
                            .font(.body)
                            .padding(.top, 5)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Join event button
                if !hasJoined && !eventsViewModel.isShowingUserEvents {
                    Button(action: {
                        joinEvent()
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Join This Event")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                    .disabled(isJoining)
                    .opacity(isJoining ? 0.6 : 1)
                    .overlay(
                        Group {
                            if isJoining {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        }
                    )
                    .padding(.horizontal)
                } else if hasJoined {
                    // Show "Joined" badge instead of join button
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("You've joined this event")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.green, lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                
                // Photos section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Photos")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                Text("Add Photo")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    if photosViewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if let errorMessage = photosViewModel.errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                    } else if photosViewModel.eventPhotos.isEmpty {
                        Text("No photos yet. Be the first to add one!")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(photosViewModel.eventPhotos) { photo in
                                    PhotoThumbnailView(photo: photo)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    if !photosViewModel.eventPhotos.isEmpty {
                        Button("Test Both URL Formats") {
                            Task {
                                for photo in photosViewModel.eventPhotos {
                                    // Get the Supabase URL from Info.plist
                                    guard let supabaseUrl = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String else {
                                        print("Missing Supabase URL configuration")
                                        return
                                    }
                                    
                                    // Clean the path
                                    let cleanPath = photo.storagePath.trimmingCharacters(in: .whitespacesAndNewlines)
                                    
                                    // Test with photos/ prefix
                                    if !cleanPath.hasPrefix("photos/") {
                                        let pathWithPrefix = "photos/\(cleanPath)"
                                        let urlString1 = "\(supabaseUrl)/storage/v1/object/public/event-photos/\(pathWithPrefix)"
                                        
                                        guard let url1 = URL(string: urlString1) else {
                                            print("Invalid URL format")
                                            continue
                                        }
                                        
                                        print("Testing URL with added photos/ prefix: \(url1)")
                                        
                                        do {
                                            let (_, response1) = try await URLSession.shared.data(from: url1)
                                            if let httpResponse1 = response1 as? HTTPURLResponse {
                                                print("URL with added prefix test result: \(httpResponse1.statusCode)")
                                            }
                                        } catch {
                                            print("URL with added prefix test error: \(error)")
                                        }
                                    }
                                    
                                    // Test without removing photos/ prefix
                                    let urlString2 = "\(supabaseUrl)/storage/v1/object/public/event-photos/\(cleanPath)"
                                    
                                    guard let url2 = URL(string: urlString2) else {
                                        print("Invalid URL format")
                                        continue
                                    }
                                    
                                    print("Testing URL without removing prefix: \(url2)")
                                    
                                    do {
                                        let (_, response2) = try await URLSession.shared.data(from: url2)
                                        if let httpResponse2 = response2 as? HTTPURLResponse {
                                            print("URL without removing prefix test result: \(httpResponse2.statusCode)")
                                        }
                                    } catch {
                                        print("URL without removing prefix test error: \(error)")
                                    }
                                }
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
                Button("Test Storage Bucket") {
                    Task {
                        // Get the Supabase URL from Info.plist
                        guard let supabaseUrl = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String else {
                            print("Missing Supabase URL configuration")
                            return
                        }
                        
                        // Test the bucket URL directly
                        let bucketUrl = "\(supabaseUrl)/storage/v1/bucket/event-photos"
                        
                        guard let url = URL(string: bucketUrl) else {
                            print("Invalid bucket URL format")
                            return
                        }
                        
                        print("Testing bucket URL: \(url)")
                        
                        do {
                            var request = URLRequest(url: url)
                            request.httpMethod = "GET"
                            
                            // Add the Supabase anon key
                            if let supabaseAnonKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String {
                                request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                            }
                            
                            let (_, response) = try await URLSession.shared.data(for: request)
                            if let httpResponse = response as? HTTPURLResponse {
                                print("Bucket test result: \(httpResponse.statusCode)")
                            }
                        } catch {
                            print("Bucket test error: \(error)")
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCamera) {
            CameraView(eventId: event.id)
        }
        .alert(isPresented: $showingJoinConfirmation) {
            if let error = joinError {
                return Alert(
                    title: Text("Error"),
                    message: Text(error),
                    dismissButton: .default(Text("OK"))
                )
            } else {
                return Alert(
                    title: Text("Success"),
                    message: Text("You've successfully joined this event!"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            photosViewModel.fetchPhotos(for: event.id)
            checkIfUserHasJoined()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func joinEvent() {
        isJoining = true
        joinError = nil
        
        Task {
            do {
                try await eventsViewModel.joinEvent(eventId: event.id)
                DispatchQueue.main.async {
                    self.isJoining = false
                    self.hasJoined = true  // Update the UI immediately
                    self.showingJoinConfirmation = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isJoining = false
                    self.joinError = error.localizedDescription
                    self.showingJoinConfirmation = true
                }
            }
        }
    }
    
    private func checkIfUserHasJoined() {
        // Check if the user has already joined this event
        Task {
            do {
                let joined = try await SupabaseService.shared.hasUserJoinedEvent(eventId: event.id)
                DispatchQueue.main.async {
                    self.hasJoined = joined
                }
            } catch {
                print("Error checking if user joined event: \(error)")
            }
        }
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EventDetailView(event: Event(
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
            ))
            .environmentObject(EventsViewModel())
        }
    }
} 