import Foundation
import UIKit
import Combine

class PhotosViewModel: ObservableObject {
    @Published var eventPhotos: [Photo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    
    func fetchPhotos(for eventId: String) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("Fetching photos for event: \(eventId)")
        
        Task {
            do {
                let photos = try await supabaseService.fetchEventPhotos(eventId: eventId)
                print("Fetched \(photos.count) photos")
                
                // Load image URLs for each photo
                var photosWithURLs: [Photo] = []
                
                for var photo in photos {
                    do {
                        let url = try supabaseService.getPhotoURL(path: photo.storagePath)
                        photo.imageURL = url
                        print("Got URL for photo \(photo.id): \(url)")
                        photosWithURLs.append(photo)
                    } catch {
                        print("Error getting URL for photo \(photo.id): \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    self.eventPhotos = photosWithURLs
                    self.isLoading = false
                    print("Updated eventPhotos with \(photosWithURLs.count) photos")
                }
            } catch {
                print("Error fetching photos: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func uploadPhoto(eventId: String, image: UIImage) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        Task {
            do {
                var photo = try await supabaseService.uploadPhoto(eventId: eventId, image: image)
                
                // Get the URL for the uploaded photo
                let url = try supabaseService.getPhotoURL(path: photo.storagePath)
                photo.imageURL = url
                photo.image = image  // Cache the image
                
                DispatchQueue.main.async {
                    self.eventPhotos.insert(photo, at: 0)
                    self.isLoading = false
                }
            } catch {
                print("Error uploading photo: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to upload photo: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
} 