import SwiftUI

struct PhotoConfirmationView: View {
    let image: UIImage
    let eventId: String
    let onRetake: () -> Void
    let onUpload: (UIImage) -> Void
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack(spacing: 50) {
                Button(action: {
                    print("Retaking photo for event: \(eventId)")
                    onRetake()
                }) {
                    VStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title)
                        Text("Retake")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                }
                
                Button(action: {
                    print("Uploading photo for event: \(eventId)")
                    onUpload(image)
                }) {
                    VStack {
                        Image(systemName: "checkmark.circle")
                            .font(.title)
                        Text("Upload")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                }
            }
            .padding(.bottom, 30)
        }
    }
}

struct PhotoConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            PhotoConfirmationView(
                image: UIImage(systemName: "photo")!,
                eventId: "test-event-id",
                onRetake: {},
                onUpload: { _ in }
            )
        }
    }
} 