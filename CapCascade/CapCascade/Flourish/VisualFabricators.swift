import SpriteKit

// MARK: - Gradient Background Fabricator

final class GradientFabricator {

    static func fabricateBackdrop(extent: CGSize,
                                  upperChroma: UIColor = ChromaticPalette.canvasTop,
                                  lowerChroma: UIColor = ChromaticPalette.canvasBottom) -> SKSpriteNode {
        let textureSize = CGSize(width: 1, height: 256)
        UIGraphicsBeginImageContextWithOptions(textureSize, true, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKSpriteNode(color: upperChroma, size: extent)
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [upperChroma.cgColor, lowerChroma.cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
            ctx.drawLinearGradient(gradient,
                                  start: CGPoint(x: 0, y: 0),
                                  end: CGPoint(x: 0, y: 256),
                                  options: [])
        }

        let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let img = renderedImage {
            let texture = SKTexture(image: img)
            let node = SKSpriteNode(texture: texture, size: extent)
            node.zPosition = -100
            return node
        }
        return SKSpriteNode(color: upperChroma, size: extent)
    }
}

// MARK: - Stylized Button Fabricator

final class StylizedButtonFabricator {

    static func fabricatePill(inscription: String,
                              extent: CGSize = CGSize(width: 220, height: 56),
                              fillChroma: UIColor = ChromaticPalette.buttonPrimary,
                              textChroma: UIColor = ChromaticPalette.ivoryText,
                              cornerArc: CGFloat = 28,
                              glyphSize: CGFloat = 20) -> SKNode {

        let container = SKNode()
        container.name = inscription

        let backdrop = SKShapeNode(rectOf: extent, cornerRadius: cornerArc)
        backdrop.fillColor = fillChroma
        backdrop.strokeColor = .clear
        backdrop.zPosition = 0

        // Subtle shadow
        let penumbra = SKShapeNode(rectOf: CGSize(width: extent.width, height: extent.height + 4),
                                   cornerRadius: cornerArc)
        penumbra.fillColor = UIColor(white: 0, alpha: 0.15)
        penumbra.strokeColor = .clear
        penumbra.position = CGPoint(x: 0, y: -3)
        penumbra.zPosition = -1

        let label = SKLabelNode(text: inscription)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = glyphSize
        label.fontColor = textChroma
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = inscription
        label.zPosition = 1

        container.addChild(penumbra)
        container.addChild(backdrop)
        container.addChild(label)

        return container
    }

    static func fabricateCircular(iconSystemName: String,
                                  diameter: CGFloat = 50,
                                  fillChroma: UIColor = ChromaticPalette.buttonPrimary) -> SKNode {
        let container = SKNode()

        let circle = SKShapeNode(circleOfRadius: diameter / 2)
        circle.fillColor = fillChroma
        circle.strokeColor = .clear
        circle.zPosition = 0

        container.addChild(circle)
        return container
    }
}

// MARK: - Lane Scaffold Fabricator

final class LaneScaffoldFabricator {

    static func fabricateLanes(count: Int,
                               sceneExtent: CGSize,
                               topMargin: CGFloat,
                               bottomMargin: CGFloat,
                               horizontalPadding: CGFloat = 20) -> [SKShapeNode] {
        var lanes: [SKShapeNode] = []
        let laneWidth = DimensionalReckoner.reckonLaneWidth(laneCount: count,
                                                            sceneWidth: sceneExtent.width,
                                                            horizontalPadding: horizontalPadding)

        for i in 0..<count {
            let xPos = DimensionalReckoner.reckonLaneXPosition(laneIndex: i,
                                                               laneCount: count,
                                                               sceneWidth: sceneExtent.width,
                                                               horizontalPadding: horizontalPadding)
            let laneHeight = sceneExtent.height - topMargin - bottomMargin
            let rect = CGRect(x: -laneWidth / 2, y: -laneHeight / 2,
                              width: laneWidth, height: laneHeight)
            let lane = SKShapeNode(rect: rect, cornerRadius: 12)
            lane.fillColor = ChromaticPalette.laneBacking
            lane.strokeColor = ChromaticPalette.laneFilament
            lane.lineWidth = 1.0
            lane.position = CGPoint(x: xPos, y: bottomMargin + laneHeight / 2)
            lane.zPosition = -5
            lane.name = "lane_\(i)"
            lanes.append(lane)
        }
        return lanes
    }
}

// MARK: - Score Placard Fabricator

final class ScorePlacardFabricator {

    static func fabricate(sceneWidth: CGFloat, yPosition: CGFloat) -> (container: SKNode, scoreLabel: SKLabelNode, timerLabel: SKLabelNode) {
        let container = SKNode()
        container.position = CGPoint(x: sceneWidth / 2, y: yPosition)
        container.zPosition = 10

        let backdrop = SKShapeNode(rectOf: CGSize(width: sceneWidth - 40, height: 50), cornerRadius: 16)
        backdrop.fillColor = UIColor(white: 1.0, alpha: 0.20)
        backdrop.strokeColor = UIColor(white: 1.0, alpha: 0.30)
        backdrop.lineWidth = 1
        container.addChild(backdrop)

        let scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontName = "AvenirNext-DemiBold"
        scoreLabel.fontSize = 18
        scoreLabel.fontColor = ChromaticPalette.obsidianText
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: -(sceneWidth / 2 - 50), y: 0)
        container.addChild(scoreLabel)

        let timerLabel = SKLabelNode(text: "00:00")
        timerLabel.fontName = "AvenirNext-DemiBold"
        timerLabel.fontSize = 18
        timerLabel.fontColor = ChromaticPalette.obsidianText
        timerLabel.horizontalAlignmentMode = .right
        timerLabel.verticalAlignmentMode = .center
        timerLabel.position = CGPoint(x: sceneWidth / 2 - 50, y: 0)
        container.addChild(timerLabel)

        return (container, scoreLabel, timerLabel)
    }
}
