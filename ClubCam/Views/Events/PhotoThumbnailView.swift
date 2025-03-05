import SwiftUI

struct PhotoThumbnailView: View {
    let photo: Photo
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var retryCount = 0
    
    var body: some View {
        ZStack {
            if let image = image {
                // Show loaded image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
            } else if let image = photo.image {
                // Show cached image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
            } else {
                // Show placeholder or loading state
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                            } else if loadError != nil {
                                VStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("Error")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        .onTapGesture {
                                            retryCount += 1
                                            loadImage()
                                        }
                                }
                            } else {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            }
                        }
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard image == nil else { return }
        
        // Try to get URL from Supabase directly if needed
        if photo.imageURL == nil || retryCount > 0 {
            Task {
                do {
                    let url = try await getDirectPhotoURL(path: photo.storagePath)
                    DispatchQueue.main.async {
                        loadImageFromURL(url)
                    }
                } catch {
                    print("Error getting direct URL: \(error)")
                    DispatchQueue.main.async {
                        loadError = "URL Error: \(error.localizedDescription)"
                    }
                }
            }
            return
        }
        
        guard let imageURL = photo.imageURL else {
            loadError = "No URL"
            print("No image URL for photo: \(photo.id)")
            return
        }
        
        loadImageFromURL(imageURL)
    }
    
    private func loadImageFromURL(_ imageURL: URL) {
        isLoading = true
        loadError = nil
        
        print("Loading image from URL: \(imageURL)")
        
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    loadError = error.localizedDescription
                    print("Error loading image: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    loadError = "Invalid response"
                    print("Invalid response")
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    loadError = "HTTP Error: \(httpResponse.statusCode)"
                    print("HTTP Error: \(httpResponse.statusCode)")
                    return
                }
                
                guard let data = data, !data.isEmpty else {
                    loadError = "Empty data"
                    print("Empty image data")
                    return
                }
                
                guard let downloadedImage = UIImage(data: data) else {
                    loadError = "Invalid image data"
                    print("Could not create image from data")
                    return
                }
                
                self.image = downloadedImage
            }
        }.resume()
    }
    
    private func getDirectPhotoURL(path: String) async throws -> URL {
        // Get the Supabase URL from Info.plist
        guard let supabaseUrl = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String else {
            throw NSError(domain: "PhotoThumbnail", code: 1006, userInfo: [NSLocalizedDescriptionKey: "Missing Supabase URL configuration"])
        }
        
        // Clean the path
        let cleanPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // IMPORTANT: Keep the "photos/" prefix - don't remove it
        // The test shows that URLs with "photos/" prefix work correctly
        
        // Properly encode the URL components
        guard let encodedPath = cleanPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw NSError(domain: "PhotoThumbnail", code: 1008, userInfo: [NSLocalizedDescriptionKey: "Failed to encode path"])
        }
        
        // Construct the URL directly
        let urlString = "\(supabaseUrl)/storage/v1/object/public/event-photos/\(encodedPath)"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "PhotoThumbnail", code: 1007, userInfo: [NSLocalizedDescriptionKey: "Invalid URL format"])
        }
        
        print("Generated direct URL in thumbnail: \(url)")
        return url
    }
} 