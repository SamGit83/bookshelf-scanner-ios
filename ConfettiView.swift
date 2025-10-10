import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        emitterLayer.emitterSize = CGSize(width: view.bounds.width, height: 1)
        emitterLayer.emitterShape = .line
        emitterLayer.birthRate = 10

        let colors: [UIColor] = [
            UIColor.systemRed.withAlphaComponent(0.8),
            UIColor.systemBlue.withAlphaComponent(0.8),
            UIColor.systemGreen.withAlphaComponent(0.8),
            UIColor.systemYellow.withAlphaComponent(0.8),
            UIColor.systemPurple.withAlphaComponent(0.8),
            UIColor.systemOrange.withAlphaComponent(0.8)
        ]

        var cells: [CAEmitterCell] = []
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 1
            cell.lifetime = 10
            cell.velocity = 100
            cell.velocityRange = 50
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 2
            cell.spinRange = 3
            cell.scale = 0.1
            cell.scaleRange = 0.05
            cell.contents = createConfettiImage(color: color).cgImage
            cells.append(cell)
        }

        emitterLayer.emitterCells = cells
        view.layer.addSublayer(emitterLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update emitter position if needed
        if let emitterLayer = uiView.layer.sublayers?.first as? CAEmitterLayer {
            emitterLayer.emitterPosition = CGPoint(x: uiView.bounds.midX, y: -10)
            emitterLayer.emitterSize = CGSize(width: uiView.bounds.width, height: 1)
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