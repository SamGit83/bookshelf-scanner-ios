import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        print("DEBUG ConfettiView: makeUIView called")
        let view = ConfettiContainerView()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        print("DEBUG ConfettiView: updateUIView called, bounds: \(uiView.bounds)")
        // No-op: ConfettiContainerView updates its emitter geometry in layoutSubviews
    }
}

final class ConfettiContainerView: UIView {
    private let emitterLayer = CAEmitterLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isUserInteractionEnabled = false

        // Configure emitter static properties
        emitterLayer.emitterShape = .line
        emitterLayer.emitterMode = .outline // switched from .surface to .outline for uniform line emission
        emitterLayer.renderMode = .additive

        // Build cells (unchanged tuning)
        let colors: [UIColor] = [
            UIColor.systemRed.withAlphaComponent(0.9),
            UIColor.systemBlue.withAlphaComponent(0.9),
            UIColor.systemGreen.withAlphaComponent(0.9),
            UIColor.systemYellow.withAlphaComponent(0.9),
            UIColor.systemPurple.withAlphaComponent(0.9),
            UIColor.systemOrange.withAlphaComponent(0.9),
            UIColor.systemPink.withAlphaComponent(0.9),
            UIColor.systemTeal.withAlphaComponent(0.9),
            UIColor.systemIndigo.withAlphaComponent(0.9),
            UIColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 0.9), // Hot pink
            UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 0.9), // Cyan
            UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.9)  // Gold
        ]

        var cells: [CAEmitterCell] = []
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 8
            cell.lifetime = 14.0
            cell.lifetimeRange = 0
            cell.velocity = 350
            cell.velocityRange = 80
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 3.5
            cell.spinRange = 4
            cell.scaleRange = 0.5
            cell.scale = 0.25
            cell.contents = createConfettiImage(color: color).cgImage
            cells.append(cell)
        }

        emitterLayer.emitterCells = cells
        layer.addSublayer(emitterLayer)

        print("DEBUG ConfettiView: Added emitter layer with \(cells.count) cells")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure geometry matches laid-out size
        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: 0)
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 1)
        emitterLayer.contentsScale = window?.screen.scale ?? UIScreen.main.scale

        print("DEBUG ConfettiView: layoutSubviews updated emitter - position: \(emitterLayer.emitterPosition), size: \(emitterLayer.emitterSize)")
    }

    private func createConfettiImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}