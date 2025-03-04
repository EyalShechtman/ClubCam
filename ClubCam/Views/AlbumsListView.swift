//
//  AlbumsListView.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import SwiftUI

struct AlbumsListView: View {
    @EnvironmentObject var albumManager: AlbumManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showingNewAlbumSheet = false
    @State private var newAlbumName = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(albumManager.albums) { album in
                    NavigationLink(destination: AlbumDetailView(albumId: album.id)) {
                        HStack {
                            if let coverImage = album.coverImage {
                                Image(uiImage: coverImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                            } else {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 40))
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(album.name)
                                    .font(.headline)
                                Text("\(album.photoCount) photos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteAlbums)
            }
            .navigationTitle("Albums")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewAlbumSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewAlbumSheet) {
                createNewAlbumView()
            }
        }
    }
    
    private func createNewAlbumView() -> some View {
        NavigationView {
            Form {
                Section(header: Text("Album Details")) {
                    TextField("Album Name", text: $newAlbumName)
                }
                
                Section {
                    Button("Create Album") {
                        if !newAlbumName.isEmpty {
                            createNewAlbum()
                        }
                    }
                    .disabled(newAlbumName.isEmpty)
                }
            }
            .navigationTitle("New Album")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingNewAlbumSheet = false
                        newAlbumName = ""
                    }
                }
            }
        }
    }
    
    private func createNewAlbum() {
        albumManager.createAlbum(name: newAlbumName)
        newAlbumName = ""
        showingNewAlbumSheet = false
    }
    
    private func deleteAlbums(at offsets: IndexSet) {
        for index in offsets {
            let album = albumManager.albums[index]
            albumManager.deleteAlbum(id: album.id)
        }
    }
}

struct AlbumsListView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumsListView()
            .environmentObject(AlbumManager())
            .environmentObject(AuthManager())
    }
} 