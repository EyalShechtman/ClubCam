//
//  AuthManager.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import Foundation
import Combine

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    // Mock authentication for development
    func signIn(email: String, password: String) {
        // In a real app, you would validate credentials against a backend
        if email.contains("@") && password.count >= 6 {
            // Simulate successful login
            let userId = UUID().uuidString
            currentUser = User(
                id: userId,
                email: email,
                username: email.components(separatedBy: "@").first,
                displayName: nil,
                avatarUrl: nil
            )
            isAuthenticated = true
        }
    }
    
    func signUp(email: String, password: String) {
        // In a real app, you would create a new user in your backend
        if email.contains("@") && password.count >= 6 {
            let userId = UUID().uuidString
            currentUser = User(
                id: userId,
                email: email,
                username: email.components(separatedBy: "@").first,
                displayName: nil,
                avatarUrl: nil
            )
            isAuthenticated = true
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
    }
}
