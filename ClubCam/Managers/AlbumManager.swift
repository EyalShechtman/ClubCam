//
//  AlbumManager.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import Foundation
import UIKit

class AlbumManager: ObservableObject {
    @Published var albums: [Album] = []
    
    init() {
        // Load albums from storage or create sample data
        loadAlbums()
    }
    
    private func loadAlbums() {
        // In a real app, you would load albums from persistent storage
        // For now, we'll create some sample data
        let sampleAlbums = [
            Album(id: UUID(), name: "Beach Day", photos: []),
            Album(id: UUID(), name: "Birthday Party", photos: []),
            Album(id: UUID(), name: "Hiking Trip", photos: [])
        ]
        
        self.albums = sampleAlbums
    }
    
    func createAlbum(name: String) -> Album {
        let newAlbum = Album(id: UUID(), name: name, photos: [])
        albums.append(newAlbum)
        return newAlbum
    }
    
    func deleteAlbum(id: UUID) {
        albums.removeAll { $0.id == id }
    }
    
    func addPhoto(to albumId: UUID, photo: Photo) {
        if let index = albums.firstIndex(where: { $0.id == albumId }) {
            albums[index].photos.append(photo)
        }
    }
    
    func getAlbum(id: UUID) -> Album? {
        return albums.first { $0.id == id }
    }
} 