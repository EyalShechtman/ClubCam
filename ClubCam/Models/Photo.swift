//
//  Photo.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import Foundation
import UIKit
import CoreLocation

struct Photo: Identifiable, Codable {
    var id: String
    var eventId: String
    var userId: String
    var storagePath: String
    var caption: String?
    var takenAt: Date
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date
    
    // Non-persisted properties
    var imageURL: URL?
    var image: UIImage?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case storagePath = "storage_path"
        case caption
        case takenAt = "taken_at"
        case latitude
        case longitude
        case createdAt = "created_at"
    }
} 