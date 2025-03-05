import SwiftUI

struct PhotoDetailView: View {
    let photo: Photo
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let image = image ?? photo.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .edgesIgnoringSafeArea(.all)
            } else if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .foregroundColor(.white)
            } else if let errorMessage = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                        .padding()
                    
                    Text("Error loading image")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .navigationBarTitle("Photo", displayMode: .inline)
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        // If we already have the image, no need to load it
        if photo.image != nil || image != nil {
            return
        }
        
        guard let imageURL = photo.imageURL else {
            errorMessage = "No image URL available"
            return
        }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            isLoading = false
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let data = data, let downloadedImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Could not load image data"
                }
                return
            }
            
            DispatchQueue.main.async {
                self.image = downloadedImage
            }
        }.resume()
    }
}

struct PhotoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PhotoDetailView(photo: Photo(
                id: "1",
                eventId: "event1",
                userId: "user1",
                storagePath: "photos/event1/photo1.jpg",
                caption: nil,
                takenAt: Date(),
                latitude: nil,
                longitude: nil,
                createdAt: Date()
            ))
        }
    }
} 