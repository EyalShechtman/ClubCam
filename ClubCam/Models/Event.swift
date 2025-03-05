import Foundation

struct Event: Identifiable, Codable {
    var id: String
    var name: String
    var description: String?
    var location: String
    var latitude: Double
    var longitude: Double
    var startTime: Date
    var endTime: Date
    var createdBy: String
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case location
        case latitude
        case longitude
        case startTime = "start_time"
        case endTime = "end_time"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct EventParticipant: Identifiable, Codable {
    let id: String
    let eventId: String
    let userId: String
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
    }
} 