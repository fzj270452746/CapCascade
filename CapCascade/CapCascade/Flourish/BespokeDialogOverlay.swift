import SpriteKit

// MARK: - Bespoke Dialog Overlay

final class BespokeDialogOverlay: SKNode {

    private let scrimNode: SKShapeNode
    private let panelNode: SKShapeNode
    private var dismissalCallback: (() -> Void)?

    init(sceneExtent: CGSize) {
        scrimNode = SKShapeNode(rectOf: sceneExtent)
        scrimNode.fillColor = ChromaticPalette.scrimOverlay
        scrimNode.strokeColor = .clear
        scrimNode.position = CGPoint(x: sceneExtent.width / 2, y: sceneExtent.height / 2)
        scrimNode.zPosition = 900

        panelNode = SKShapeNode()
        panelNode.zPosition = 910

        super.init()
        self.zPosition = 900
        self.isUserInteractionEnabled = true
        addChild(scrimNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Game Over Dialog

    static func fabricateGameOverDialog(
        sceneExtent: CGSize,
        finalScore: Int,
        elapsedTime: TimeInterval,
        arenaKind: TallyLedger.ArenaKind,
        onReplay: @escaping () -> Void,
        onEgress: @escaping () -> Void
    ) -> BespokeDialogOverlay {

        let overlay = BespokeDialogOverlay(sceneExtent: sceneExtent)

        let panelWidth = min(sceneExtent.width - 60, 320)
        let panelHeight: CGFloat = 340
        let panel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 24)
        panel.fillColor = UIColor.white
        panel.strokeColor = UIColor(white: 0.9, alpha: 1.0)
        panel.lineWidth = 1
        panel.position = CGPoint(x: sceneExtent.width / 2, y: sceneExtent.height / 2)
        panel.zPosition = 910

        // Title
        let titleLabel = SKLabelNode(text: "Game Over")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 28
        titleLabel.fontColor = ChromaticPalette.coralEmber
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 110)
        panel.addChild(titleLabel)

        // Decorative line
        let separator = SKShapeNode(rectOf: CGSize(width: panelWidth - 60, height: 2), cornerRadius: 1)
        separator.fillColor = UIColor(white: 0.92, alpha: 1.0)
        separator.strokeColor = .clear
        separator.position = CGPoint(x: 0, y: 80)
        panel.addChild(separator)

        // Score
        let scoreCaption = SKLabelNode(text: "SCORE")
        scoreCaption.fontName = "AvenirNext-Medium"
        scoreCaption.fontSize = 13
        scoreCaption.fontColor = ChromaticPalette.slateCaption
        scoreCaption.verticalAlignmentMode = .center
        scoreCaption.position = CGPoint(x: 0, y: 55)
        panel.addChild(scoreCaption)

        let scoreValue = SKLabelNode(text: "\(finalScore)")
        scoreValue.fontName = "AvenirNext-Bold"
        scoreValue.fontSize = 42
        scoreValue.fontColor = ChromaticPalette.obsidianText
        scoreValue.verticalAlignmentMode = .center
        scoreValue.position = CGPoint(x: 0, y: 20)
        panel.addChild(scoreValue)

        // Time
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let timeCaption = SKLabelNode(text: "TIME")
        timeCaption.fontName = "AvenirNext-Medium"
        timeCaption.fontSize = 13
        timeCaption.fontColor = ChromaticPalette.slateCaption
        timeCaption.verticalAlignmentMode = .center
        timeCaption.position = CGPoint(x: 0, y: -15)
        panel.addChild(timeCaption)

        let timeValue = SKLabelNode(text: String(format: "%02d:%02d", minutes, seconds))
        timeValue.fontName = "AvenirNext-DemiBold"
        timeValue.fontSize = 24
        timeValue.fontColor = ChromaticPalette.obsidianText
        timeValue.verticalAlignmentMode = .center
        timeValue.position = CGPoint(x: 0, y: -42)
        panel.addChild(timeValue)

        // Replay button
        let replayBtn = StylizedButtonFabricator.fabricatePill(
            inscription: "btn_replay",
            extent: CGSize(width: panelWidth - 80, height: 48),
            fillChroma: ChromaticPalette.buttonPrimary,
            cornerArc: 24,
            glyphSize: 18
        )
        // Replace label text
        if let lbl = replayBtn.childNode(withName: "btn_replay") as? SKLabelNode {
            lbl.text = "Play Again"
        }
        replayBtn.position = CGPoint(x: 0, y: -85)
        replayBtn.name = "btn_replay"
        panel.addChild(replayBtn)

        // Exit button
        let exitBtn = StylizedButtonFabricator.fabricatePill(
            inscription: "btn_egress",
            extent: CGSize(width: panelWidth - 80, height: 48),
            fillChroma: ChromaticPalette.slateCaption,
            cornerArc: 24,
            glyphSize: 18
        )
        if let lbl = exitBtn.childNode(withName: "btn_egress") as? SKLabelNode {
            lbl.text = "Main Menu"
        }
        exitBtn.position = CGPoint(x: 0, y: -140)
        exitBtn.name = "btn_egress"
        panel.addChild(exitBtn)

        overlay.addChild(panel)
        overlay.onReplayHandler = onReplay
        overlay.onEgressHandler = onEgress

        // Animate entrance
        panel.setScale(0.6)
        panel.alpha = 0
        panel.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.3),
            SKAction.fadeIn(withDuration: 0.3)
        ]))

        return overlay
    }

    // MARK: - Pause Dialog

    static func fabricatePauseDialog(
        sceneExtent: CGSize,
        onResume: @escaping () -> Void,
        onEgress: @escaping () -> Void
    ) -> BespokeDialogOverlay {

        let overlay = BespokeDialogOverlay(sceneExtent: sceneExtent)

        let panelWidth = min(sceneExtent.width - 60, 280)
        let panelHeight: CGFloat = 240
        let panel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 24)
        panel.fillColor = UIColor.white
        panel.strokeColor = UIColor(white: 0.9, alpha: 1.0)
        panel.lineWidth = 1
        panel.position = CGPoint(x: sceneExtent.width / 2, y: sceneExtent.height / 2)
        panel.zPosition = 910

        let titleLabel = SKLabelNode(text: "Paused")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 28
        titleLabel.fontColor = ChromaticPalette.lavendelMist
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 65)
        panel.addChild(titleLabel)

        let resumeBtn = StylizedButtonFabricator.fabricatePill(
            inscription: "btn_resume",
            extent: CGSize(width: panelWidth - 60, height: 48),
            fillChroma: ChromaticPalette.buttonSuccess,
            cornerArc: 24,
            glyphSize: 18
        )
        if let lbl = resumeBtn.childNode(withName: "btn_resume") as? SKLabelNode {
            lbl.text = "Resume"
        }
        resumeBtn.position = CGPoint(x: 0, y: 5)
        resumeBtn.name = "btn_resume"
        panel.addChild(resumeBtn)

        let exitBtn = StylizedButtonFabricator.fabricatePill(
            inscription: "btn_egress",
            extent: CGSize(width: panelWidth - 60, height: 48),
            fillChroma: ChromaticPalette.slateCaption,
            cornerArc: 24,
            glyphSize: 18
        )
        if let lbl = exitBtn.childNode(withName: "btn_egress") as? SKLabelNode {
            lbl.text = "Main Menu"
        }
        exitBtn.position = CGPoint(x: 0, y: -55)
        exitBtn.name = "btn_egress"
        panel.addChild(exitBtn)

        overlay.addChild(panel)
        overlay.onResumeHandler = onResume
        overlay.onEgressHandler = onEgress

        panel.setScale(0.6)
        panel.alpha = 0
        panel.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.25),
            SKAction.fadeIn(withDuration: 0.25)
        ]))

        return overlay
    }

    // MARK: - Tutorial Dialog

    static func fabricateTutorialDialog(
        sceneExtent: CGSize,
        title: String,
        paragraphs: [String],
        titleColor: UIColor = ChromaticPalette.zephyrBlue,
        onDismiss: @escaping () -> Void
    ) -> BespokeDialogOverlay {

        let overlay = BespokeDialogOverlay(sceneExtent: sceneExtent)

        let panelWidth = min(sceneExtent.width - 40, 340)
        let lineHeight: CGFloat = 18
        let paragraphSpacing: CGFloat = 8
        let headerHeight: CGFloat = 65   // title + separator + top padding
        let footerHeight: CGFloat = 70   // button + bottom padding
        let maxChars = Int(panelWidth - 56) / 7

        // Pre-compute all wrapped lines
        var allLines: [(text: String, isGap: Bool)] = []
        for paragraph in paragraphs {
            if paragraph.isEmpty {
                allLines.append(("", true))
            } else {
                let wrapped = wrapText(paragraph, maxCharsPerLine: maxChars)
                for line in wrapped {
                    allLines.append((line, false))
                }
                allLines.append(("", true)) // gap after paragraph
            }
        }

        // Calculate exact text content height
        var textHeight: CGFloat = 0
        for line in allLines {
            textHeight += line.isGap ? paragraphSpacing : lineHeight
        }

        let panelHeight = min(headerHeight + textHeight + footerHeight, sceneExtent.height - 80)
        let panel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 24)
        panel.fillColor = UIColor.white
        panel.strokeColor = UIColor(white: 0.9, alpha: 1.0)
        panel.lineWidth = 1
        panel.position = CGPoint(x: sceneExtent.width / 2, y: sceneExtent.height / 2)
        panel.zPosition = 910

        // Title
        let titleLabel = SKLabelNode(text: title)
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 24
        titleLabel.fontColor = titleColor
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: panelHeight / 2 - 35)
        panel.addChild(titleLabel)

        // Separator
        let separator = SKShapeNode(rectOf: CGSize(width: panelWidth - 60, height: 2), cornerRadius: 1)
        separator.fillColor = UIColor(white: 0.92, alpha: 1.0)
        separator.strokeColor = .clear
        separator.position = CGPoint(x: 0, y: panelHeight / 2 - 55)
        panel.addChild(separator)

        // Content lines — stop before overlapping the button
        var cursorY = panelHeight / 2 - 72
        let textInset = -(panelWidth / 2 - 28)
        let buttonTopBound = -panelHeight / 2 + footerHeight + 5

        for line in allLines {
            if cursorY < buttonTopBound { break }
            if line.isGap {
                cursorY -= paragraphSpacing
            } else {
                let lineLabel = SKLabelNode(text: line.text)
                lineLabel.fontName = "AvenirNext-Medium"
                lineLabel.fontSize = 13
                lineLabel.fontColor = ChromaticPalette.obsidianText
                lineLabel.horizontalAlignmentMode = .left
                lineLabel.verticalAlignmentMode = .center
                lineLabel.position = CGPoint(x: textInset, y: cursorY)
                panel.addChild(lineLabel)
                cursorY -= lineHeight
            }
        }

        // Dismiss button — always at panel bottom
        let dismissBtn = StylizedButtonFabricator.fabricatePill(
            inscription: "btn_dismiss",
            extent: CGSize(width: panelWidth - 80, height: 48),
            fillChroma: ChromaticPalette.buttonPrimary,
            cornerArc: 24,
            glyphSize: 18
        )
        if let lbl = dismissBtn.childNode(withName: "btn_dismiss") as? SKLabelNode {
            lbl.text = "Got It!"
        }
        dismissBtn.position = CGPoint(x: 0, y: -panelHeight / 2 + 40)
        dismissBtn.name = "btn_dismiss"
        panel.addChild(dismissBtn)

        overlay.addChild(panel)
        overlay.onDismissHandler = onDismiss

        // Animate entrance
        panel.setScale(0.6)
        panel.alpha = 0
        panel.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.3),
            SKAction.fadeIn(withDuration: 0.3)
        ]))

        return overlay
    }

    // MARK: - Text Wrapping Helper

    private static func wrapText(_ text: String, maxCharsPerLine: Int) -> [String] {
        let words = text.split(separator: " ").map(String.init)
        var lines: [String] = []
        var currentLine = ""

        for word in words {
            if currentLine.isEmpty {
                currentLine = word
            } else if currentLine.count + 1 + word.count <= maxCharsPerLine {
                currentLine += " " + word
            } else {
                lines.append(currentLine)
                currentLine = word
            }
        }
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        return lines
    }

    // MARK: - Touch Handling

    private var onReplayHandler: (() -> Void)?
    private var onResumeHandler: (() -> Void)?
    private var onEgressHandler: (() -> Void)?
    private var onDismissHandler: (() -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        for node in tappedNodes {
            if node.name == "btn_replay" || node.parent?.name == "btn_replay" {
                HapticCourier.communal.emitTap()
                animateButtonPress(node.name == "btn_replay" ? node : node.parent!) {
                    self.onReplayHandler?()
                    self.dissolveOverlay()
                }
                return
            }
            if node.name == "btn_resume" || node.parent?.name == "btn_resume" {
                HapticCourier.communal.emitTap()
                animateButtonPress(node.name == "btn_resume" ? node : node.parent!) {
                    self.onResumeHandler?()
                    self.dissolveOverlay()
                }
                return
            }
            if node.name == "btn_egress" || node.parent?.name == "btn_egress" {
                HapticCourier.communal.emitTap()
                animateButtonPress(node.name == "btn_egress" ? node : node.parent!) {
                    self.onEgressHandler?()
                    self.dissolveOverlay()
                }
                return
            }
            if node.name == "btn_dismiss" || node.parent?.name == "btn_dismiss" {
                HapticCourier.communal.emitTap()
                animateButtonPress(node.name == "btn_dismiss" ? node : node.parent!) {
                    self.onDismissHandler?()
                    self.dissolveOverlay()
                }
                return
            }
        }
    }

    private func animateButtonPress(_ node: SKNode, completion: @escaping () -> Void) {
        let shrink = SKAction.scale(to: 0.92, duration: 0.08)
        let grow = SKAction.scale(to: 1.0, duration: 0.08)
        node.run(SKAction.sequence([shrink, grow])) {
            completion()
        }
    }

    private func dissolveOverlay() {
        self.run(SKAction.fadeOut(withDuration: 0.2)) {
            self.removeFromParent()
        }
    }
}
