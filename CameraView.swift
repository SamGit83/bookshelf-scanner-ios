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
        // Enhanced gradient background for top bar
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.6).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        topBar.layer.addSublayer(gradientLayer)
        containerView.addSubview(topBar)
        
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // Update gradient frame when layout changes
        DispatchQueue.main.async {
            gradientLayer.frame = topBar.bounds
        }
        
        // Enhanced Close button with vibrant styling
        let closeButton = createVibrantButton(title: "Close",
                                            backgroundColor: UIColor(red: 1.0, green: 0.18, blue: 0.57, alpha: 0.9), // Hot Pink
                                            isDestructive: true)
        closeButton.addTarget(coordinator, action: #selector(CameraView.Coordinator.cancelCapture), for: .touchUpInside)
        topBar.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 20),
            closeButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 80),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Enhanced Flash button (only if device has flash)
        if hasFlash {
            flashButton = createEnhancedFlashButton()
            flashButton?.addTarget(coordinator, action: #selector(CameraView.Coordinator.toggleFlash), for: .touchUpInside)
            topBar.addSubview(flashButton!)
            
            NSLayoutConstraint.activate([
                flashButton!.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -20),
                flashButton!.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
                flashButton!.widthAnchor.constraint(equalToConstant: 50),
                flashButton!.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
    }
    
    private func setupBottomBar(in containerView: UIView) {
        let bottomBar = UIView()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        // Enhanced gradient background for bottom bar
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        bottomBar.layer.addSublayer(gradientLayer)
        containerView.addSubview(bottomBar)
        
        NSLayoutConstraint.activate([
            bottomBar.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 140)
        ])
        
        // Update gradient frame when layout changes
        DispatchQueue.main.async {
            gradientLayer.frame = bottomBar.bounds
        }
        
        // Enhanced Capture button with vibrant styling
        let captureButton = UIButton()
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Create vibrant gradient background
        let captureGradientLayer = CAGradientLayer()
        captureGradientLayer.colors = [
            UIColor(red: 1.0, green: 0.18, blue: 0.57, alpha: 1.0).cgColor, // Hot Pink
            UIColor(red: 0.35, green: 0.34, blue: 0.84, alpha: 1.0).cgColor  // Purple
        ]
        captureGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        captureGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        captureGradientLayer.cornerRadius = 45
        captureButton.layer.insertSublayer(captureGradientLayer, at: 0)
        
        captureButton.layer.cornerRadius = 45
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        captureButton.addTarget(coordinator, action: #selector(CameraView.Coordinator.capturePhoto), for: .touchUpInside)
        
        // Enhanced shadow for depth
        captureButton.layer.shadowColor = UIColor(red: 1.0, green: 0.18, blue: 0.57, alpha: 0.6).cgColor
        captureButton.layer.shadowOffset = CGSize(width: 0, height: 8)
        captureButton.layer.shadowRadius = 16
        captureButton.layer.shadowOpacity = 0.4
        
        // Add camera icon
        let cameraIcon = UIImageView(image: UIImage(systemName: "camera.fill"))
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        cameraIcon.tintColor = .white
        cameraIcon.contentMode = .scaleAspectFit
        cameraIcon.isUserInteractionEnabled = false
        captureButton.addSubview(cameraIcon)
        
        bottomBar.addSubview(captureButton)
        
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            captureButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 90),
            captureButton.heightAnchor.constraint(equalToConstant: 90),
            
            cameraIcon.centerXAnchor.constraint(equalTo: captureButton.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            cameraIcon.widthAnchor.constraint(equalToConstant: 32),
            cameraIcon.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        // Update gradient frame when layout changes
        DispatchQueue.main.async {
            captureGradientLayer.frame = captureButton.bounds
        }
        
        // Enhanced Cancel button
        let cancelButton = createVibrantButton(title: "Cancel",
                                             backgroundColor: UIColor.white.withAlphaComponent(0.15),
                                             isDestructive: false)
        cancelButton.addTarget(coordinator, action: #selector(CameraView.Coordinator.cancelCapture), for: .touchUpInside)
        bottomBar.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            cancelButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupWarningMessage(in containerView: UIView) {
        let warningContainer = UIView()
        warningContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Enhanced glass effect background
        warningContainer.backgroundColor = UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 0.9) // Dynamic Orange
        warningContainer.layer.cornerRadius = 16
        
        // Add glass effect border
        warningContainer.layer.borderWidth = 1
        warningContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        // Enhanced shadow
        warningContainer.layer.shadowColor = UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 0.4).cgColor
        warningContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        warningContainer.layer.shadowRadius = 12
        warningContainer.layer.shadowOpacity = 0.3
        
        containerView.addSubview(warningContainer)
        
        let warningIcon = UIImageView(image: UIImage(systemName: "lightbulb.fill"))
        warningIcon.translatesAutoresizingMaskIntoConstraints = false
        warningIcon.tintColor = .white
        warningIcon.contentMode = .scaleAspectFit
        warningContainer.addSubview(warningIcon)
        
        let warningLabel = UILabel()
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.text = "Good lighting improves book detection accuracy"
        warningLabel.textColor = .white
        warningLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        warningLabel.numberOfLines = 2
        warningLabel.textAlignment = .left
        warningContainer.addSubview(warningLabel)
        
        NSLayoutConstraint.activate([
            warningContainer.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 120),
            warningContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            warningContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            warningContainer.heightAnchor.constraint(equalToConstant: 60),
            
            warningIcon.leadingAnchor.constraint(equalTo: warningContainer.leadingAnchor, constant: 16),
            warningIcon.centerYAnchor.constraint(equalTo: warningContainer.centerYAnchor),
            warningIcon.widthAnchor.constraint(equalToConstant: 24),
            warningIcon.heightAnchor.constraint(equalToConstant: 24),
            
            warningLabel.leadingAnchor.constraint(equalTo: warningIcon.trailingAnchor, constant: 12),
            warningLabel.trailingAnchor.constraint(equalTo: warningContainer.trailingAnchor, constant: -16),
            warningLabel.centerYAnchor.constraint(equalTo: warningContainer.centerYAnchor)
        ])
    }
    
    private func createVibrantButton(title: String, backgroundColor: UIColor, isDestructive: Bool) -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 22
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        // Add glass effect border
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        // Enhanced shadow with color
        if isDestructive {
            button.layer.shadowColor = UIColor(red: 1.0, green: 0.18, blue: 0.57, alpha: 0.4).cgColor
        } else {
            button.layer.shadowColor = UIColor.black.cgColor
        }
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.3
        
        return button
    }
    
    private func createEnhancedFlashButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        button.layer.cornerRadius = 25
        button.setImage(UIImage(systemName: "bolt.slash"), for: .normal)
        button.tintColor = .white
        
        // Add glass effect border
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        // Enhanced shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.3
        
        return button
    }
    
    @objc private func flashToggled(_ notification: Notification) {
        guard let isOn = notification.object as? Bool else { return }
        
        DispatchQueue.main.async { [weak self] in
            let imageName = isOn ? "bolt.fill" : "bolt.slash"
            let backgroundColor = isOn ? UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.9) : UIColor.white.withAlphaComponent(0.15) // Neon Yellow when on
            
            self?.flashButton?.setImage(UIImage(systemName: imageName), for: .normal)
            self?.flashButton?.backgroundColor = backgroundColor
            self?.flashButton?.tintColor = isOn ? .black : .white
            
            // Add pulsing animation when flash is on
            if isOn {
                let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
                pulseAnimation.duration = 0.6
                pulseAnimation.fromValue = 1.0
                pulseAnimation.toValue = 1.1
                pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                pulseAnimation.autoreverses = true
                pulseAnimation.repeatCount = .infinity
                self?.flashButton?.layer.add(pulseAnimation, forKey: "pulse")
            } else {
                self?.flashButton?.layer.removeAnimation(forKey: "pulse")
            }
        }
    }
}
