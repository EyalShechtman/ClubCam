//
//  MainTabView.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var albumManager: AlbumManager
    
    var body: some View {
        TabView {
            AlbumsListView()
                .tabItem {
                    Label("Albums", systemImage: "photo.on.rectangle")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .onAppear {
            // Albums are loaded in the AlbumManager init
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AlbumManager())
            .environmentObject(AuthManager())
    }
} 