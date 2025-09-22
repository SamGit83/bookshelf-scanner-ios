import SwiftUI
import AVFoundation
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isShowingCamera: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        print("DEBUG CameraView: makeUIViewController called")
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("DEBUG CameraView: Camera authorization status: \(status.rawValue)")
        if status == .notDetermined {
            print("DEBUG CameraView: Requesting camera access")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    print("DEBUG CameraView: Camera access \(granted ? "granted" : "denied")")
                }
            }
        }

        let viewController = CameraViewController()
        let captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("DEBUG CameraView: No video capture device available")
            return viewController
        }
        print("DEBUG CameraView: Video capture device found")
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return viewController
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            print("DEBUG CameraView: Added video input to session")
        } else {
            print("DEBUG CameraView: Cannot add video input to session")
            return viewController
        }

        // Add photo output
        let photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            context.coordinator.photoOutput = photoOutput
            print("DEBUG CameraView: Added photo output to session")
        } else {
            print("DEBUG CameraView: Cannot add photo output to session")
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
        print("DEBUG CameraView: Capture session started")

        // Setup the camera view controller
        viewController.setupUI(coordinator: context.coordinator, previewLayer: previewLayer, captureDevice: videoCaptureDevice)

        context.coordinator.captureSession = captureSession
        context.coordinator.previewLayer = previewLayer
        context.coordinator.captureDevice = videoCaptureDevice

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let cameraVC = uiViewController as? CameraViewController,
           let previewLayer = context.coordinator.previewLayer {
            previewLayer.frame = cameraVC.view.layer.bounds
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
        var captureDevice: AVCaptureDevice?
        var isFlashOn = false

        init(_ parent: CameraView) {
            self.parent = parent
            super.init()
            print("DEBUG Coordinator: Initialized")
        }

        @objc func capturePhoto() {
            print("DEBUG Coordinator: capturePhoto called")
            let settings = AVCapturePhotoSettings()
            
            // Set flash mode based on current state
            if let device = captureDevice, device.hasFlash {
                settings.flashMode = isFlashOn ? .on : .off
            }
            
            photoOutput?.capturePhoto(with: settings, delegate: self)
        }

        @objc func cancelCapture() {
            print("DEBUG Coordinator: cancelCapture called")
            // Turn off torch if it's on
            toggleTorch(false)
            parent.isShowingCamera = false
        }
        
        @objc func toggleFlash() {
            isFlashOn.toggle()
            toggleTorch(isFlashOn)
            
            // Update flash button appearance
            NotificationCenter.default.post(name: NSNotification.Name("FlashToggled"), object: isFlashOn)
        }
        
        private func toggleTorch(_ on: Bool) {
            guard let device = captureDevice, device.hasTorch else { return }
            
            do {
                try device.lockForConfiguration()
                device.torchMode = on ? .on : .off
                device.unlockForConfiguration()
            } catch {
                print("DEBUG Coordinator: Failed to toggle torch: \(error)")
            }
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            print("DEBUG Coordinator: photoOutput didFinishProcessingPhoto, error: \(error?.localizedDescription ?? "none")")
            if let imageData = photo.fileDataRepresentation() {
                print("DEBUG Coordinator: imageData count: \(imageData.count)")
                if let image = UIImage(data: imageData) {
                    print("DEBUG Coordinator: Image captured successfully, size: \(image.size)")
                    parent.capturedImage = image
                    // Turn off torch after capture
                    toggleTorch(false)
                    parent.isShowingCamera = false
                } else {
                    print("DEBUG Coordinator: Failed to create UIImage from imageData")
                }
            } else {
                print("DEBUG Coordinator: fileDataRepresentation returned nil")
            }
        }
    }
}

class CameraViewController: UIViewController {
    private var coordinator: CameraView.Coordinator?
    private var flashButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // Listen for flash toggle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(flashToggled(_:)),
            name: NSNotification.Name("FlashToggled"),
            object: nil
        )
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update preview layer frame when layout changes
        if let previewLayer = coordinator?.previewLayer {
            previewLayer.frame = view.layer.bounds
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupUI(coordinator: CameraView.Coordinator, previewLayer: AVCaptureVideoPreviewLayer, captureDevice: AVCaptureDevice) {
        self.coordinator = coordinator
        previewLayer.frame = view.layer.bounds
        
        // Create overlay view
        let overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .clear
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        setupTopBar(in: overlayView, hasFlash: captureDevice.hasFlash)
        setupBottomBar(in: overlayView)
        setupWarningMessage(in: overlayView)
    }
    
    private func setupTopBar(in containerView: UIView, hasFlash: Bool) {
        let topBar = UIView()
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = UIColor(white: 0, alpha: 0.4)
        containerView.addSubview(topBar)
        
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Close button
        let closeButton = createStyledButton(title: "Close", backgroundColor: UIColor.white.withAlphaComponent(0.2))
        closeButton.addTarget(coordinator, action: #selector(CameraView.Coordinator.cancelCapture), for: .touchUpInside)
        topBar.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 20),
            closeButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 70),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Flash button (only if device has flash)
        if hasFlash {
            flashButton = createFlashButton()
            flashButton?.addTarget(coordinator, action: #selector(CameraView.Coordinator.toggleFlash), for: .touchUpInside)
            topBar.addSubview(flashButton!)
            
            NSLayoutConstraint.activate([
                flashButton!.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -20),
                flashButton!.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
                flashButton!.widthAnchor.constraint(equalToConstant: 44),
                flashButton!.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
    }
    
    private func setupBottomBar(in containerView: UIView) {
        let bottomBar = UIView()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.backgroundColor = UIColor(white: 0, alpha: 0.4)
        containerView.addSubview(bottomBar)
        
        NSLayoutConstraint.activate([
            bottomBar.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        // Capture button with Liquid Glass effect
        let captureButton = UIButton()
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        captureButton.layer.cornerRadius = 40
        captureButton.layer.borderWidth = 3
        captureButton.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        captureButton.addTarget(coordinator, action: #selector(CameraView.Coordinator.capturePhoto), for: .touchUpInside)
        
        // Add shadow for depth
        captureButton.layer.shadowColor = UIColor.black.cgColor
        captureButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        captureButton.layer.shadowRadius = 8
        captureButton.layer.shadowOpacity = 0.3
        
        // Add inner circle for better visual
        let innerCircle = UIView()
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        innerCircle.layer.cornerRadius = 30
        innerCircle.isUserInteractionEnabled = false
        captureButton.addSubview(innerCircle)
        
        bottomBar.addSubview(captureButton)
        
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            captureButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 80),
            captureButton.heightAnchor.constraint(equalToConstant: 80),
            
            innerCircle.centerXAnchor.constraint(equalTo: captureButton.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 60),
            innerCircle.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Cancel button
        let cancelButton = createStyledButton(title: "Cancel", backgroundColor: UIColor.white.withAlphaComponent(0.2))
        cancelButton.addTarget(coordinator, action: #selector(CameraView.Coordinator.cancelCapture), for: .touchUpInside)
        bottomBar.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            cancelButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 70),
            cancelButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func setupWarningMessage(in containerView: UIView) {
        let warningContainer = UIView()
        warningContainer.translatesAutoresizingMaskIntoConstraints = false
        warningContainer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.9)
        warningContainer.layer.cornerRadius = 12
        containerView.addSubview(warningContainer)
        
        let warningIcon = UILabel()
        warningIcon.translatesAutoresizingMaskIntoConstraints = false
        warningIcon.text = "⚠️"
        warningIcon.font = UIFont.systemFont(ofSize: 16)
        warningContainer.addSubview(warningIcon)
        
        let warningLabel = UILabel()
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.text = "Good lighting improves book detection accuracy"
        warningLabel.textColor = .white
        warningLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        warningLabel.numberOfLines = 2
        warningLabel.textAlignment = .left
        warningContainer.addSubview(warningLabel)
        
        NSLayoutConstraint.activate([
            warningContainer.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 100),
            warningContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            warningContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            warningContainer.heightAnchor.constraint(equalToConstant: 50),
            
            warningIcon.leadingAnchor.constraint(equalTo: warningContainer.leadingAnchor, constant: 12),
            warningIcon.centerYAnchor.constraint(equalTo: warningContainer.centerYAnchor),
            
            warningLabel.leadingAnchor.constraint(equalTo: warningIcon.trailingAnchor, constant: 8),
            warningLabel.trailingAnchor.constraint(equalTo: warningContainer.trailingAnchor, constant: -12),
            warningLabel.centerYAnchor.constraint(equalTo: warningContainer.centerYAnchor)
        ])
    }
    
    private func createStyledButton(title: String, backgroundColor: UIColor) -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 18
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // Add subtle shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        
        return button
    }
    
    private func createFlashButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 22
        button.setImage(UIImage(systemName: "bolt.slash"), for: .normal)
        button.tintColor = .white
        
        // Add subtle shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        
        return button
    }
    
    @objc private func flashToggled(_ notification: Notification) {
        guard let isOn = notification.object as? Bool else { return }
        
        DispatchQueue.main.async { [weak self] in
            let imageName = isOn ? "bolt" : "bolt.slash"
            let backgroundColor = isOn ? UIColor.systemYellow.withAlphaComponent(0.8) : UIColor.white.withAlphaComponent(0.2)
            
            self?.flashButton?.setImage(UIImage(systemName: imageName), for: .normal)
            self?.flashButton?.backgroundColor = backgroundColor
            self?.flashButton?.tintColor = isOn ? .black : .white
        }
    }
}
