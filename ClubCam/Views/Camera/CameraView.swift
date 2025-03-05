import SwiftUI
import AVFoundation

struct CameraView: View {
    let eventId: String
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var cameraViewModel = CameraViewModel()
    @StateObject private var photosViewModel = PhotosViewModel()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if cameraViewModel.capturedImage != nil {
                // Show photo confirmation view
                PhotoConfirmationView(
                    image: cameraViewModel.capturedImage!,
                    eventId: eventId,
                    onRetake: {
                        cameraViewModel.resetCapturedImage()
                    },
                    onUpload: { image in
                        savePhoto(image)
                    }
                )
            } else {
                // Show camera preview
                CameraPreviewView(session: cameraViewModel.session)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            cameraViewModel.capturePhoto()
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                        .frame(width: 60, height: 60)
                                )
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
            }
            
            // Error message
            if let errorMessage = cameraViewModel.errorMessage {
                VStack {
                    Text("Camera Error")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(15)
                .padding()
            }
            
            // Loading indicator
            if photosViewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
        }
        .onAppear {
            cameraViewModel.startSession()
        }
        .onDisappear {
            cameraViewModel.stopSession()
        }
        .alert(isPresented: $cameraViewModel.showingConfirmation) {
            Alert(
                title: Text("Success"),
                message: Text("Photo uploaded successfully!"),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert(isPresented: $cameraViewModel.showingError) {
            Alert(
                title: Text("Error"),
                message: Text(cameraViewModel.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func savePhoto(_ image: UIImage) {
        let eventIdToUpload = eventId

        cameraViewModel.isUploading = true
        cameraViewModel.errorMessage = nil
        
        Task {
            do {
                print("Starting photo upload for event: \(eventId)")
                await photosViewModel.uploadPhoto(eventId: eventId, image: image)
                
                DispatchQueue.main.async {
                    self.cameraViewModel.isUploading = false
                    self.cameraViewModel.showingConfirmation = true
                    self.cameraViewModel.capturedImage = nil
                }
            } catch {
                print("Error in CameraView.savePhoto: \(error)")
                
                DispatchQueue.main.async {
                    self.cameraViewModel.isUploading = false
                    self.cameraViewModel.errorMessage = error.localizedDescription
                    self.cameraViewModel.showingError = true
                }
            }
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(eventId: "test-event-id")
    }
} 
