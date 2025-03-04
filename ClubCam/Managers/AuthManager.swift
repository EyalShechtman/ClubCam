//
//  AuthManager.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import Foundation
import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        // In a real app, you would implement actual authentication logic here
        // For now, we'll simulate a successful login
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isAuthenticated = true
            self.currentUser = User(
                id: UUID().uuidString,
                email: email,
                joinDate: Date(),
                displayName: email.components(separatedBy: "@").first
            )
            completion(true)
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (Bool) -> Void) {
        // In a real app, you would implement actual account creation logic here
        // For now, we'll simulate a successful signup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isAuthenticated = true
            self.currentUser = User(
                id: UUID().uuidString,
                email: email,
                joinDate: Date(),
                displayName: email.components(separatedBy: "@").first
            )
            completion(true)
        }
    }
    
    func logout() {
        // In a real app, you would clear tokens, etc.
        isAuthenticated = false
        currentUser = nil
    }
}
