//
//  ProfileView.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(authManager.currentUser?.email ?? "User")
                                .font(.headline)
                            Text("Member since \(authManager.currentUser?.joinDate.formatted(date: .abbreviated, time: .omitted) ?? "recently")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Settings")) {
                    NavigationLink(destination: Text("Notification Settings")) {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink(destination: Text("Privacy Settings")) {
                        Label("Privacy", systemImage: "lock.shield")
                    }
                    
                    NavigationLink(destination: Text("Storage Settings")) {
                        Label("Storage & Data", systemImage: "internaldrive")
                    }
                }
                
                Section {
                    Button(action: { showingLogoutAlert = true }) {
                        Label("Log Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthManager())
    }
} 
