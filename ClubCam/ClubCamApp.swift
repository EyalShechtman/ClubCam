//
//  ClubCamApp.swift
//  ClubCam
//
//  Created by Nadya Shechtman on 3/4/25.
//

import SwiftUI

@main
struct ClubCamApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var eventsViewModel = EventsViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(eventsViewModel)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                EventsListView()
            } else {
                LoginView()
            }
        }
    }
}
