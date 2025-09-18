import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isShowingCamera: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return viewController }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return viewController
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return viewController
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)

        captureSession.startRunning()

        // Add capture button
        // Add Liquid Glass overlay
        let overlayView = UIView(frame: viewController.view.bounds)
        overlayView.backgroundColor = .clear

        // Top control bar
        let topBar = UIView(frame: CGRect(x: 0, y: 0, width: viewController.view.bounds.width, height: 100))
        topBar.backgroundColor = UIColor(white: 0, alpha: 0.3)
        overlayView.addSubview(topBar)

        // Bottom control bar
        let bottomBar = UIView(frame: CGRect(x: 0, y: viewController.view.bounds.height - 120, width: viewController.view.bounds.width, height: 120))
        bottomBar.backgroundColor = UIColor(white: 0, alpha: 0.4)
        overlayView.addSubview(bottomBar)

        // Capture button with Liquid Glass effect
        let captureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        captureButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        captureButton.layer.cornerRadius = 40
        captureButton.layer.borderWidth = 2
        captureButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        captureButton.center = CGPoint(x: bottomBar.center.x, y: bottomBar.frame.height / 2)
        captureButton.addTarget(context.coordinator, action: #selector(Coordinator.capturePhoto), for: .touchUpInside)

        // Add shadow for depth
        captureButton.layer.shadowColor = UIColor.black.cgColor
        captureButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        captureButton.layer.shadowRadius = 8
        captureButton.layer.shadowOpacity = 0.3

        bottomBar.addSubview(captureButton)

        // Cancel button
        let cancelButton = UIButton(frame: CGRect(x: 20, y: bottomBar.frame.height / 2 - 15, width: 60, height: 30))
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        cancelButton.layer.cornerRadius = 15
        cancelButton.addTarget(context.coordinator, action: #selector(Coordinator.cancelCapture), for: .touchUpInside)
        bottomBar.addSubview(cancelButton)

        viewController.view.addSubview(overlayView)

        context.coordinator.captureSession = captureSession
        context.coordinator.previewLayer = previewLayer

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            previewLayer.frame = uiViewController.view.layer.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraView
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var photoOutput: AVCapturePhotoOutput?

        init(_ parent: CameraView) {
            self.parent = parent
            super.init()

            // Add photo output
            photoOutput = AVCapturePhotoOutput()
            if let photoOutput = photoOutput, let captureSession = captureSession, captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
        }

        @objc func capturePhoto() {
            let settings = AVCapturePhotoSettings()
            photoOutput?.capturePhoto(with: settings, delegate: self)
        }

        @objc func cancelCapture() {
            parent.isShowingCamera = false
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let imageData = photo.fileDataRepresentation(),
               let image = UIImage(data: imageData) {
                parent.capturedImage = image
                parent.isShowingCamera = false
            }
        }
    }
}