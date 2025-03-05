//
//  User.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    var username: String?
    var displayName: String?
    var avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
} 