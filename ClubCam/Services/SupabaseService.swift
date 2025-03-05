import Foundation
import Supabase
import UIKit

class SupabaseService {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    private init() {
        guard let supabaseUrl = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              let supabaseAnonKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String else {
            fatalError("Missing Supabase configuration. Please check your Info.plist file.")
        }
        
        self.client = SupabaseClient(
            supabaseURL: URL(string: supabaseUrl)!,
            supabaseKey: supabaseAnonKey
        )
    }
    
    // MARK: - Auth Methods
    
    func signUp(email: String, password: String) async throws -> User {
        let authResponse = try await client.auth.signUp(
            email: email,
            password: password
        )

        let authUser = authResponse.user
        let userId = authUser.id.uuidString

        return User(
            id: userId,
            email: authUser.email ?? "",
            username: nil,
            displayName: nil,
            avatarUrl: nil
        )
    }

    func signIn(email: String, password: String) async throws -> User {
        let authResponse = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        let authUser = authResponse.user
        let userId = authUser.id.uuidString

        return User(
            id: userId,
            email: authUser.email ?? "",
            username: nil,
            displayName: nil,
            avatarUrl: nil
        )
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // MARK: - Events Methods
    
    func fetchNearbyEvents(latitude: Double, longitude: Double) async throws -> [Event] {
        do {
            let response = try await client.rpc("nearby_events", params: [
                "lat": latitude,
                "lng": longitude,
                "radius_km": 5000
            ]).execute()
            
            let data = response.data
            
//            print("Raw JSON for nearby events: \(String(data: data, encoding: .utf8) ?? "Could not convert to string")")
            
            // Create a custom decoder with a more flexible date decoding strategy
            let decoder = JSONDecoder()
            
            // Custom date formatter that can handle the format from Supabase
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Try multiple date formats
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
                
                // Try ISO8601 as fallback
                let iso8601Formatter = ISO8601DateFormatter()
                iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
                
                // Try without fractional seconds
                iso8601Formatter.formatOptions = [.withInternetDateTime]
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
            }
            
            do {
                return try decoder.decode([Event].self, from: data)
            } catch {
                print("JSON Decoding Error: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Key not found: \(key), context: \(context)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: \(type), context: \(context)")
                    case .valueNotFound(let type, let context):
                        print("Value not found: \(type), context: \(context)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                
                // As a fallback, try to manually parse the JSON
                return parseEventsManually(from: data)
            }
        } catch {
            print("RPC Error: \(error)")
            throw error
        }
    }
    
    // Manual JSON parsing as a fallback
    private func parseEventsManually(from data: Data) -> [Event] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        
        return json.compactMap { eventDict -> Event? in
            guard 
                let id = eventDict["id"] as? String,
                let name = eventDict["name"] as? String,
                let location = eventDict["location"] as? String,
                let latitude = eventDict["latitude"] as? Double,
                let longitude = eventDict["longitude"] as? Double,
                let startTimeString = eventDict["start_time"] as? String,
                let endTimeString = eventDict["end_time"] as? String,
                let createdBy = eventDict["created_by"] as? String,
                let createdAtString = eventDict["created_at"] as? String,
                let updatedAtString = eventDict["updated_at"] as? String
            else {
                return nil
            }
            
            // Parse dates manually
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let startTime = dateFormatter.date(from: startTimeString) ?? Date()
            let endTime = dateFormatter.date(from: endTimeString) ?? Date()
            let createdAt = dateFormatter.date(from: createdAtString) ?? Date()
            let updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
            
            return Event(
                id: id,
                name: name,
                description: eventDict["description"] as? String,
                location: location,
                latitude: latitude,
                longitude: longitude,
                startTime: startTime,
                endTime: endTime,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }
    
    func fetchUserEvents() async throws -> [Event] {
        do {
            // Get the current session
            let sessionResponse = try await client.auth.session
            let userId = sessionResponse.user.id.uuidString
            
            print("Fetching events for user: \(userId)")
            
            // First, get the event IDs the user has joined
            let response = try await client.database
                .from("event_participants")
                .select("event_id")
                .eq("user_id", value: userId)
                .execute()
            
            print("Event participants response: \(String(data: response.data, encoding: .utf8) ?? "No data")")
            
            // Parse the JSON manually
            guard let participantsJson = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] else {
                print("Failed to parse participants JSON")
                return []
            }
            
            // Extract event IDs
            let eventIds = participantsJson.compactMap { $0["event_id"] as? String }
            
            print("Found \(eventIds.count) event IDs: \(eventIds)")
            
            if eventIds.isEmpty {
                return []
            }
            
            // Fix: Don't add quotes around the UUIDs in the IN clause
            // Instead, use individual eq queries with .or operator
            var query = client.database
                .from("events")
                .select("*")
            
            // Build the query with OR conditions for each event ID
            if let firstId = eventIds.first {
                query = query.eq("id", value: firstId)
                
                for id in eventIds.dropFirst() {
                    query = query.or("id.eq.\(id)")
                }
            }
            
            let eventsResponse = try await query.execute()
            
            print("Events response: \(String(data: eventsResponse.data, encoding: .utf8) ?? "No data")")
            
            // Use our custom date decoder
            let decoder = JSONDecoder()
            
            // Custom date formatter
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Try multiple date formats
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
                
                // Try ISO8601 as fallback
                let iso8601Formatter = ISO8601DateFormatter()
                iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
                
                // Try without fractional seconds
                iso8601Formatter.formatOptions = [.withInternetDateTime]
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
            }
            
            do {
                return try decoder.decode([Event].self, from: eventsResponse.data)
            } catch {
                print("Error decoding events: \(error)")
                return parseEventsManually(from: eventsResponse.data)
            }
        } catch {
            print("Error in fetchUserEvents: \(error)")
            throw error
        }
    }
    
    func createEvent(event: Event) async throws -> Event {
        let response = try await client.database
            .from("events")
            .insert(event)
            .execute()

        let data = response.data

        guard let eventObj = try? JSONDecoder().decode([Event].self, from: data).first else {
            throw NSError(domain: "SupabaseService", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Failed to create event"])
        }

        return eventObj
    }
    
    func joinEvent(eventId: String) async throws {
        // Get the current session
        let sessionResponse = try await client.auth.session
        let userId = sessionResponse.user.id.uuidString

        let participant = EventParticipant(
            id: UUID().uuidString,
            eventId: eventId,
            userId: userId,
            joinedAt: Date()
        )
        
        _ = try await client.database
            .from("event_participants")
            .insert(participant)
            .execute()
    }
    
    // MARK: - Photos Methods
    
    func uploadPhoto(eventId: String, image: UIImage) async throws -> Photo {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "SupabaseService", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // Get the current session
        let sessionResponse = try await client.auth.session
        let userId = sessionResponse.user.id.uuidString
        
        let fileName = "\(UUID().uuidString).jpg"
        let storagePath = "photos/\(eventId)/\(fileName)"
        
        print("Uploading photo to storage path: \(storagePath)")
        
        // First upload the file to storage
        do {
            _ = try await client.storage
                .from("event-photos")
                .upload(storagePath, data: imageData)

            print("Successfully uploaded image to storage")
        } catch {
            print("Storage upload error: \(error)")
            throw error
        }
        
        // Create the photo record in the database
        let photo = Photo(
            id: UUID().uuidString,
            eventId: eventId,
            userId: userId,
            storagePath: storagePath,
            caption: nil,
            takenAt: Date(),
            latitude: nil,
            longitude: nil,
            createdAt: Date()
        )
        
        print("Creating photo record with ID: \(photo.id)")
        
        // Insert the photo record
        do {
            let response = try await client.database
                .from("photos")
                .insert(photo, returning: .representation)
                .execute()
            
            let data = response.data
            print("Photo insert response: \(String(data: data, encoding: .utf8) ?? "No data")")
            
            // Use our custom date decoder
            let decoder = JSONDecoder()
            
            // Custom date formatter
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Try multiple date formats
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
                
                // Try ISO8601 as fallback
                let iso8601Formatter = ISO8601DateFormatter()
                iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
                
                // Try without fractional seconds
                iso8601Formatter.formatOptions = [.withInternetDateTime]
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
            }
            
            do {
                let photos = try decoder.decode([Photo].self, from: data)
                if let uploadedPhoto = photos.first {
                    return uploadedPhoto
                } else {
                    throw NSError(domain: "SupabaseService", code: 1005, userInfo: [NSLocalizedDescriptionKey: "No photo returned after insertion"])
                }
            } catch {
                print("Error decoding photo: \(error)")
                
                // As a fallback, return the original photo
                return photo
            }
        } catch {
            print("Database insert error: \(error)")
            throw error
        }
    }
    
    func fetchEventPhotos(eventId: String) async throws -> [Photo] {
        let response = try await client.from("photos")
            .select("*")
            .eq("event_id", value: eventId)
            .order("taken_at", ascending: false)
            .execute()
        
        let data = response.data
        print("Fetched photos response: \(String(data: data, encoding: .utf8) ?? "No data")")
        
        // Use our custom date decoder
        let decoder = JSONDecoder()
        
        // Custom date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try multiple date formats
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            // Try ISO8601 as fallback
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Try without fractional seconds
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        
        do {
            return try decoder.decode([Photo].self, from: data)
        } catch {
            print("Error decoding photos: \(error)")
            return []
        }
    }
    
    func getPhotoURL(path: String) throws -> URL {
        // Make sure the path is properly formatted
        let cleanPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("Getting public URL for path: \(cleanPath)")
        
        // IMPORTANT: We need to keep the "photos/" prefix if it exists
        // The test shows that URLs with "photos/" prefix work correctly
        
        // Get the Supabase URL from Info.plist
        guard let supabaseUrl = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String else {
            throw NSError(domain: "SupabaseService", code: 1006, userInfo: [NSLocalizedDescriptionKey: "Missing Supabase URL configuration"])
        }
        
        // Properly encode the URL components
        guard let encodedPath = cleanPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw NSError(domain: "SupabaseService", code: 1008, userInfo: [NSLocalizedDescriptionKey: "Failed to encode path"])
        }
        
        // Construct the URL directly instead of using the SDK
        let urlString = "\(supabaseUrl)/storage/v1/object/public/event-photos/\(encodedPath)"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "SupabaseService", code: 1007, userInfo: [NSLocalizedDescriptionKey: "Invalid URL format"])
        }
        
        print("Generated direct public URL: \(url)")
        return url
    }
    
    func hasUserJoinedEvent(eventId: String) async throws -> Bool {
        // Get the current session
        let sessionResponse = try await client.auth.session
        let userId = sessionResponse.user.id.uuidString
        
        // Check if the user has joined this event
        let response = try await client.database
            .from("event_participants")
            .select("*")
            .eq("event_id", value: eventId)
            .eq("user_id", value: userId)
            .execute()
        
        // Parse the response
        let data = response.data
        let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        
        // If we found any records, the user has joined
        return !json.isEmpty
    }
} 
