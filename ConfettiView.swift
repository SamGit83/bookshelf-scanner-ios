import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let emitterLayer = CAEmitterLayer()
        // Will be set properly in updateUIView when bounds are available
        emitterLayer.emitterPosition = CGPoint(x: 0, y: 0)
        emitterLayer.emitterSize = CGSize(width: 0, height: 0)
        emitterLayer.emitterShape = .line
        emitterLayer.birthRate = 6

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
            cell.birthRate = 1
            cell.lifetime = 5
            cell.velocity = 150
            cell.velocityRange = 100
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 2
            cell.spin = 4
            cell.spinRange = 6
            cell.scale = 0.15
            cell.scaleRange = 0.1
            cell.contents = createConfettiImage(color: color).cgImage
            cells.append(cell)
        }

        emitterLayer.emitterCells = cells
        view.layer.addSublayer(emitterLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update emitter position to center top of screen
        if let emitterLayer = uiView.layer.sublayers?.first as? CAEmitterLayer {
            emitterLayer.emitterPosition = CGPoint(x: uiView.bounds.width / 2, y: 0)
            // Set emitter size to a small width so confetti emits from center point
            emitterLayer.emitterSize = CGSize(width: 50, height: 0)
        }
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