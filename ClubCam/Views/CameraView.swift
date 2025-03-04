import SwiftUI
import AVFoundation

struct CameraView: View {
    let albumId: UUID
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var albumManager: AlbumManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var cameraModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraModel.session)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.7)))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        cameraModel.capturePhoto { image in
                            if let image = image {
                                let photo = Photo(
                                    id: UUID(), 
                                    image: image, 
                                    dateTaken: Date(),
                                    takenBy: authManager.currentUser?.displayName ?? "Unknown"
                                )
                                albumManager.addPhoto(to: albumId, photo: photo)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 70, height: 70)
                            )
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        cameraModel.switchCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.title)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.7)))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            cameraModel.checkPermissions()
        }
    }
}

class CameraViewModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    private var camera: AVCaptureDevice?
    private var photoOutput = AVCapturePhotoOutput()
    private var completionHandler: ((UIImage?) -> Void)?
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                setupCamera()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    if granted {
                        DispatchQueue.main.async {
                            self?.setupCamera()
                        }
                    }
                }
            default:
                break
        }
    }
    
    func setupCamera() {
        do {
            session.beginConfiguration()
            
            // Add video input - this is likely where the crash is happening
            camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            
            // Check if camera is available before unwrapping
            guard let camera = camera else {
                print("Error: Could not access camera")
                session.commitConfiguration()
                return
            }
            
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            // Add photo output
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
            
            session.commitConfiguration()
            session.startRunning()
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    func switchCamera() {
        session.beginConfiguration()
        
        // Remove existing input
        for input in session.inputs {
            session.removeInput(input)
        }
        
        // Get new camera position
        let position: AVCaptureDevice.Position = (camera?.position == .back) ? .front : .back
        camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
        
        // Check if camera is available before unwrapping
        guard let camera = camera else {
            print("Error: Could not access camera")
            session.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Error switching camera: \(error.localizedDescription)")
        }
        
        session.commitConfiguration()
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.completionHandler = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            completionHandler?(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completionHandler?(nil)
            return
        }
        
        completionHandler?(image)
    }
}

struct CameraPreview: UIViewRepresentable {
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