import Foundation
import SpriteKit

// MARK: - Chromatic Palette

struct ChromaticPalette {

    // Primary gradient colors
    static let zephyrBlue    = UIColor(red: 0.40, green: 0.69, blue: 0.97, alpha: 1.0)
    static let lavendelMist  = UIColor(red: 0.68, green: 0.53, blue: 0.95, alpha: 1.0)
    static let coralEmber    = UIColor(red: 0.96, green: 0.45, blue: 0.45, alpha: 1.0)
    static let mintDew       = UIColor(red: 0.40, green: 0.90, blue: 0.72, alpha: 1.0)
    static let amberGleam    = UIColor(red: 1.00, green: 0.78, blue: 0.28, alpha: 1.0)

    // Background
    static let canvasTop     = UIColor(red: 0.93, green: 0.95, blue: 1.00, alpha: 1.0)
    static let canvasBottom  = UIColor(red: 0.82, green: 0.87, blue: 0.97, alpha: 1.0)

    // UI Elements
    static let ivoryText     = UIColor.white
    static let obsidianText  = UIColor(red: 0.18, green: 0.18, blue: 0.25, alpha: 1.0)
    static let slateCaption  = UIColor(red: 0.45, green: 0.45, blue: 0.55, alpha: 1.0)

    // Track / Lane
    static let laneFilament  = UIColor(white: 1.0, alpha: 0.25)
    static let laneBacking   = UIColor(white: 1.0, alpha: 0.10)

    // Button
    static let buttonPrimary = UIColor(red: 0.38, green: 0.55, blue: 0.98, alpha: 1.0)
    static let buttonDanger  = UIColor(red: 0.93, green: 0.36, blue: 0.36, alpha: 1.0)
    static let buttonSuccess = UIColor(red: 0.30, green: 0.82, blue: 0.60, alpha: 1.0)

    // Overlay
    static let scrimOverlay  = UIColor(white: 0.0, alpha: 0.55)
}

// MARK: - Dimensional Reckoner

struct DimensionalReckoner {

    static func reckonSafeArea(forScene scene: SKScene) -> UIEdgeInsets {
        guard let viewFrame = scene.view else {
            return .zero
        }
        if #available(iOS 15.0, *) {
            return viewFrame.safeAreaInsets
        } else {
            return viewFrame.safeAreaInsets
        }
    }

    static func reckonSceneExtent() -> CGSize {
        let screenBounds = UIScreen.main.bounds
        return CGSize(width: screenBounds.width, height: screenBounds.height)
    }

    static func reckonLaneWidth(laneCount: Int, sceneWidth: CGFloat, horizontalPadding: CGFloat = 20) -> CGFloat {
        let usableWidth = sceneWidth - (horizontalPadding * 2)
        return usableWidth / CGFloat(laneCount)
    }

    static func reckonLaneXPosition(laneIndex: Int, laneCount: Int, sceneWidth: CGFloat, horizontalPadding: CGFloat = 20) -> CGFloat {
        let laneWidth = reckonLaneWidth(laneCount: laneCount, sceneWidth: sceneWidth, horizontalPadding: horizontalPadding)
        return horizontalPadding + laneWidth * CGFloat(laneIndex) + laneWidth / 2.0
    }

    static func reckonCapDimension(laneWidth: CGFloat) -> CGFloat {
        return min(laneWidth * 0.75, 70)
    }
}

// MARK: - Haptic Courier

final class HapticCourier {

    static let communal = HapticCourier()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGen = UINotificationFeedbackGenerator()

    private init() {
        impactLight.prepare()
        impactMedium.prepare()
        notificationGen.prepare()
    }

    func emitTap() {
        impactLight.impactOccurred()
    }

    func emitThud() {
        impactMedium.impactOccurred()
    }

    func emitTriumph() {
        notificationGen.notificationOccurred(.success)
    }

    func emitCalamity() {
        notificationGen.notificationOccurred(.error)
    }
}

// MARK: - Acoustic Conductor

final class AcousticConductor {

    static let communal = AcousticConductor()

    private init() {}

    func emitMatchChime(inScene scene: SKScene) {
        scene.run(SKAction.playSoundFileNamed("match.wav", waitForCompletion: false))
    }

    func emitEliminateChime(inScene scene: SKScene) {
        scene.run(SKAction.playSoundFileNamed("eliminate.wav", waitForCompletion: false))
    }

    func emitFailureChime(inScene scene: SKScene) {
        scene.run(SKAction.playSoundFileNamed("failure.wav", waitForCompletion: false))
    }
}
