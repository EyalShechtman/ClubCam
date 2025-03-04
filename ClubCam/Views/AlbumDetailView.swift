//
//  AlbumDetailView.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import SwiftUI

struct AlbumDetailView: View {
    let albumId: UUID
    @EnvironmentObject var albumManager: AlbumManager
    @State private var showingCamera = false
    @State private var showingExportOptions = false
    
    var album: Album? {
        albumManager.getAlbum(id: albumId)
    }
    
    var body: some View {
        VStack {
            if let album = album {
                if album.photos.isEmpty {
                    Text("No photos yet")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                            ForEach(album.photos) { photo in
                                NavigationLink(destination: PhotoDetailView(photo: photo)) {
                                    Image(uiImage: photo.image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                    }
                }
            } else {
                Text("Album not found")
                    .font(.title)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .navigationTitle(album?.name ?? "Album")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingExportOptions = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(album?.photos.isEmpty ?? true)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCamera = true }) {
                    Image(systemName: "camera")
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(albumId: albumId)
        }
        .sheet(isPresented: $showingExportOptions) {
            if let album = album {
                ExportOptionsView(album: album)
            }
        }
        .onAppear {
            // No need to load photos separately as they're part of the album
        }
    }
}

struct AlbumDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AlbumDetailView(albumId: UUID())
                .environmentObject(AlbumManager())
        }
    }
} 