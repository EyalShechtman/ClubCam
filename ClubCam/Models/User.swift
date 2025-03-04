//
//  User.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import Foundation

struct User: Identifiable {
    let id: String
    let email: String
    let joinDate: Date
    
    // Additional user properties can be added here
    var displayName: String?
    var profileImageURL: URL?
    
    var username: String {
        return displayName ?? email.components(separatedBy: "@").first ?? "User"
    }
} 