import SwiftUI
import AVFoundation
import UIKit
import CoreImage

// Apple Books Design System Constants for Camera Interface
struct AppleBooksCameraColors {
    static let background = UIColor(Color(hex: "F2F2F7"))  // Light gray background
    static let card = UIColor.white                          // Pure white cards
    static let text = UIColor.black                           // Primary black text
    static let textSecondary = UIColor(Color(hex: "3C3C4399")) // 60% opacity gray
    static let accent = UIColor(Color(hex: "FF9F0A"))       // Warm orange for CTAs
    static let overlayBackground = UIColor.white.withAlphaComponent(0.1) // Subtle overlay
    static let glassBorder = UIColor.white.withAlphaComponent(0.2)
}

struct AppleBooksCameraTypography {
    static let buttonLarge = UIFont.systemFont(ofSize: 17, weight: .semibold)
    static let buttonMedium = UIFont.systemFont(ofSize: 15, weight: .medium)
    static let caption = UIFont.systemFont(ofSize: 12, weight: .regular)
}

struct AppleBooksCameraSpacing {
    static let space8: CGFloat = 8
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16
    static let space20: CGFloat = 20
    static let space24: CGFloat = 24
    static let space32: CGFloat = 32
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isShowingCamera: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                }
            }
        }

        let viewController = CameraViewController()
        let captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return viewController
        }
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

        // Add photo output
        let photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            context.coordinator.photoOutput = photoOutput
        } else {
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)

        captureSession.startRunning()

        // Setup the camera view controller
        viewController.setupUI(coordinator: context.coordinator, previewLayer: previewLayer, captureDevice: videoCaptureDevice)

        context.coordinator.viewController = viewController
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
        weak var viewController: CameraViewController?

        init(_ parent: CameraView) {
            self.parent = parent
            super.init()
        }

        @objc func capturePhoto() {
            let settings = AVCapturePhotoSettings()
            
            // Set flash mode based on current state
            if let device = captureDevice, device.hasFlash {
                settings.flashMode = isFlashOn ? .on : .off
            }
            
            photoOutput?.capturePhoto(with: settings, delegate: self)
        }

        @objc func cancelCapture() {
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
            }
        }

        private func validateImageQuality(_ image: UIImage) -> Bool {
            guard let ciImage = CIImage(image: image) else { return false }

            // Check brightness
            let brightnessFilter = CIFilter(name: "CIAreaAverage")!
            brightnessFilter.setValue(ciImage, forKey: kCIInputImageKey)
            guard let outputImage = brightnessFilter.outputImage else { return false }

            let context = CIContext()
            var bitmap = [UInt8](repeating: 0, count: 4)
            context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
            let brightness = Double(bitmap[0]) / 255.0

            // Check if brightness is reasonable (not too dark or too bright)
            if brightness < 0.1 || brightness > 0.9 {
                return false
            }

            // Basic blur check using variance (simplified)
            // For more accurate blur detection, would need Vision framework
            // But for now, assume if brightness is ok, it's good

            return true
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let imageData = photo.fileDataRepresentation() {
                if let image = UIImage(data: imageData) {
                    if validateImageQuality(image) {
                        parent.capturedImage = image
                        // Turn off torch after capture
                        toggleTorch(false)
                        parent.isShowingCamera = false
                    } else {
                        guard let vc = viewController else { return }
                        let alert = UIAlertController(title: "Image Quality Issue", message: "The image may be too dark/bright. Ensure good lighting and try adjusting your distance from the bookshelf.\n\nTry moving closer or farther to fit the bookshelf in the frame", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: nil))
                        alert.addAction(UIAlertAction(title: "Proceed Anyway", style: .default) { _ in
                            self.parent.capturedImage = image
                            self.toggleTorch(false)
                            self.parent.isShowingCamera = false
                        })
                        vc.present(alert, animated: true)
                        // Do not set capturedImage or close camera by default, allow user to try again or proceed
                    }
                } else {
                }
            } else {
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
        setupGuidanceOverlays(in: overlayView)
    }

    private func setupGuidanceOverlays(in containerView: UIView) {
        // Framing guides - rectangle in center
        let framingView = UIView()
        framingView.translatesAutoresizingMaskIntoConstraints = false
        framingView.backgroundColor = .clear
        framingView.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        framingView.layer.borderWidth = 2
        framingView.layer.cornerRadius = 8
        containerView.addSubview(framingView)

        NSLayoutConstraint.activate([
            framingView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            framingView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            framingView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.95),
            framingView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.6)
        ])

        // Tips label at the top
        let tipsLabel = UILabel()
        tipsLabel.translatesAutoresizingMaskIntoConstraints = false
        tipsLabel.text = "Adjust distance to fit bookshelf in frame • Ensure good lighting • Hold steady for focus"
        tipsLabel.textColor = .white
        tipsLabel.font = AppleBooksCameraTypography.caption
        tipsLabel.textAlignment = .center
        tipsLabel.numberOfLines = 0
        tipsLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        tipsLabel.layer.cornerRadius = 8
        tipsLabel.clipsToBounds = true
        containerView.addSubview(tipsLabel)

        NSLayoutConstraint.activate([
            tipsLabel.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 80),
            tipsLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: AppleBooksCameraSpacing.space20),
            tipsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -AppleBooksCameraSpacing.space20),
            tipsLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])

        // Focus indicator (small circle in center)
        let focusIndicator = UIView()
        focusIndicator.translatesAutoresizingMaskIntoConstraints = false
        focusIndicator.backgroundColor = .clear
        focusIndicator.layer.borderColor = UIColor.green.withAlphaComponent(0.8).cgColor
        focusIndicator.layer.borderWidth = 1
        focusIndicator.layer.cornerRadius = 20
        containerView.addSubview(focusIndicator)

        NSLayoutConstraint.activate([
            focusIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            focusIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            focusIndicator.widthAnchor.constraint(equalToConstant: 40),
            focusIndicator.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupTopBar(in containerView: UIView, hasFlash: Bool) {
        let topBar = UIView()
        topBar.translatesAutoresizingMaskIntoConstraints = false
        // Clean overlay background with subtle glass effect
        topBar.backgroundColor = AppleBooksCameraColors.overlayBackground
        topBar.layer.borderWidth = 0.5
        topBar.layer.borderColor = AppleBooksCameraColors.glassBorder.cgColor
        containerView.addSubview(topBar)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 60)
        ])

        // Clean Close button
        let closeButton = createCleanButton(title: "Close", isPrimary: false)
        closeButton.addTarget(coordinator, action: #selector(CameraView.Coordinator.cancelCapture), for: .touchUpInside)
        topBar.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: AppleBooksCameraSpacing.space20),
            closeButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 70),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        // Clean Flash button (only if device has flash)
        if hasFlash {
            flashButton = createCleanFlashButton()
            flashButton?.addTarget(coordinator, action: #selector(CameraView.Coordinator.toggleFlash), for: .touchUpInside)
            topBar.addSubview(flashButton!)

            NSLayoutConstraint.activate([
                flashButton!.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -AppleBooksCameraSpacing.space20),
                flashButton!.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
                flashButton!.widthAnchor.constraint(equalToConstant: 44),
                flashButton!.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
    }
    
    private func setupBottomBar(in containerView: UIView) {
        let bottomBar = UIView()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        // Clean overlay background with subtle glass effect
        bottomBar.backgroundColor = AppleBooksCameraColors.overlayBackground
        bottomBar.layer.borderWidth = 0.5
        bottomBar.layer.borderColor = AppleBooksCameraColors.glassBorder.cgColor
        containerView.addSubview(bottomBar)

        NSLayoutConstraint.activate([
            bottomBar.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 100)
        ])

        // Clean Capture button with 3D-style depth
        let captureButton = UIButton()
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.backgroundColor = AppleBooksCameraColors.card
        captureButton.layer.cornerRadius = 35
        captureButton.layer.borderWidth = 2
        captureButton.layer.borderColor = AppleBooksCameraColors.glassBorder.cgColor
        captureButton.addTarget(coordinator, action: #selector(CameraView.Coordinator.capturePhoto), for: .touchUpInside)

        // Subtle shadow for depth
        captureButton.layer.shadowColor = UIColor.black.cgColor
        captureButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        captureButton.layer.shadowRadius = 4
        captureButton.layer.shadowOpacity = 0.1

        // Add camera icon
        let cameraIcon = UIImageView(image: UIImage(systemName: "camera.fill"))
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        cameraIcon.tintColor = AppleBooksCameraColors.text
        cameraIcon.contentMode = .scaleAspectFit
        cameraIcon.isUserInteractionEnabled = false
        captureButton.addSubview(cameraIcon)

        bottomBar.addSubview(captureButton)

        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            captureButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),

            cameraIcon.centerXAnchor.constraint(equalTo: captureButton.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            cameraIcon.widthAnchor.constraint(equalToConstant: 24),
            cameraIcon.heightAnchor.constraint(equalToConstant: 24)
        ])

        // Clean Cancel button
        let cancelButton = createCleanButton(title: "Cancel", isPrimary: false)
        cancelButton.addTarget(coordinator, action: #selector(CameraView.Coordinator.cancelCapture), for: .touchUpInside)
        bottomBar.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: AppleBooksCameraSpacing.space20),
            cancelButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 70),
            cancelButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    
    private func createCleanButton(title: String, isPrimary: Bool) -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(isPrimary ? AppleBooksCameraColors.card : AppleBooksCameraColors.text, for: .normal)
        button.backgroundColor = isPrimary ? AppleBooksCameraColors.accent : AppleBooksCameraColors.card
        button.layer.cornerRadius = 18
        button.titleLabel?.font = AppleBooksCameraTypography.buttonMedium

        // Subtle border and shadow
        button.layer.borderWidth = 1
        button.layer.borderColor = AppleBooksCameraColors.glassBorder.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 2
        button.layer.shadowOpacity = 0.1

        return button
    }

    private func createCleanFlashButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = AppleBooksCameraColors.card
        button.layer.cornerRadius = 22
        button.setImage(UIImage(systemName: "bolt.slash"), for: .normal)
        button.tintColor = AppleBooksCameraColors.text

        // Subtle border and shadow
        button.layer.borderWidth = 1
        button.layer.borderColor = AppleBooksCameraColors.glassBorder.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 2
        button.layer.shadowOpacity = 0.1

        return button
    }
    
    @objc private func flashToggled(_ notification: Notification) {
        guard let isOn = notification.object as? Bool else { return }

        DispatchQueue.main.async { [weak self] in
            let imageName = isOn ? "bolt.fill" : "bolt.slash"
            let backgroundColor = isOn ? AppleBooksCameraColors.accent : AppleBooksCameraColors.card

            self?.flashButton?.setImage(UIImage(systemName: imageName), for: .normal)
            self?.flashButton?.backgroundColor = backgroundColor
            self?.flashButton?.tintColor = isOn ? AppleBooksCameraColors.card : AppleBooksCameraColors.text

            // Subtle animation when flash is on
            if isOn {
                let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
                scaleAnimation.duration = 0.2
                scaleAnimation.fromValue = 1.0
                scaleAnimation.toValue = 1.05
                scaleAnimation.autoreverses = true
                self?.flashButton?.layer.add(scaleAnimation, forKey: "scale")
            } else {
                self?.flashButton?.layer.removeAnimation(forKey: "scale")
            }
        }
    }
}
