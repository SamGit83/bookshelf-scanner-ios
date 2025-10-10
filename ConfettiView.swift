import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        print("DEBUG ConfettiView: makeUIView called")
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false

        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: -10)
        emitterLayer.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 1)
        emitterLayer.emitterShape = .line
        emitterLayer.renderMode = .additive

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
            cell.birthRate = 4
            cell.lifetime = 14.0
            cell.lifetimeRange = 0
            cell.velocity = 350
            cell.velocityRange = 80
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 3.5
            cell.spinRange = 4
            cell.scaleRange = 0.25
            cell.scale = 0.1
            cell.contents = createConfettiImage(color: color).cgImage
            cells.append(cell)
        }

        emitterLayer.emitterCells = cells
        view.layer.addSublayer(emitterLayer)
        
        print("DEBUG ConfettiView: Added emitter layer with \(cells.count) cells")
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        print("DEBUG ConfettiView: updateUIView called, bounds: \(uiView.bounds)")
        if let emitterLayer = uiView.layer.sublayers?.first as? CAEmitterLayer {
            emitterLayer.emitterPosition = CGPoint(x: uiView.bounds.width / 2, y: -10)
            emitterLayer.emitterSize = CGSize(width: uiView.bounds.width, height: 1)
            print("DEBUG ConfettiView: Updated emitter - position: \(emitterLayer.emitterPosition), size: \(emitterLayer.emitterSize), birthRate: \(emitterLayer.birthRate ?? 0)")
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