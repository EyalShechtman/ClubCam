//
//  ClubCamApp.swift
//  ClubCam
//
//  Created by Nadya Shechtman on 3/4/25.
//

import SwiftUI

@main
struct ClubCamApp: App {
    // Add StateObjects for app-wide state management
    @StateObject private var authManager = AuthManager()
    @StateObject private var albumManager = AlbumManager()
    
    var body: some Scene {
        WindowGroup {
            // Pass the managers to ContentView
            ContentView()
                .environmentObject(authManager)
                .environmentObject(albumManager)
        }
    }
}
