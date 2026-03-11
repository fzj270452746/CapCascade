import SpriteKit

// MARK: - Main Menu Scene

final class VestibuleScene: SKScene {

    private var floatingCaps: [SKSpriteNode] = []

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0, y: 0)
        erectorBackdrop()
        erectorTitle()
        erectorMenuButtons()
        erectorFloatingAmbience()
    }

    // MARK: - Backdrop

    private func erectorBackdrop() {
        let bg = GradientFabricator.fabricateBackdrop(
            extent: size,
            upperChroma: UIColor(red: 0.88, green: 0.92, blue: 1.0, alpha: 1.0),
            lowerChroma: UIColor(red: 0.72, green: 0.80, blue: 0.96, alpha: 1.0)
        )
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(bg)
    }

    // MARK: - Title

    private func erectorTitle() {
        let titleContainer = SKNode()
        titleContainer.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        titleContainer.zPosition = 10

        // App name
        let titleLabel = SKLabelNode(text: "Cap Cascade")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 38
        titleLabel.fontColor = ChromaticPalette.obsidianText
        titleLabel.verticalAlignmentMode = .center
        titleContainer.addChild(titleLabel)

        // Subtitle
        let subtitleLabel = SKLabelNode(text: "Match the Hats!")
        subtitleLabel.fontName = "AvenirNext-Medium"
        subtitleLabel.fontSize = 16
        subtitleLabel.fontColor = ChromaticPalette.slateCaption
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: 0, y: -35)
        titleContainer.addChild(subtitleLabel)

        // Decorative hat icons row
        let hatTypes = CapVariant.allCases
        let spacing: CGFloat = 42
        let totalWidth = spacing * CGFloat(hatTypes.count - 1)
        let startX = -totalWidth / 2

        for (idx, variant) in hatTypes.enumerated() {
            let hatSprite = SKSpriteNode(texture: variant.texturePlacard)
            hatSprite.size = CGSize(width: 32, height: 32)
            hatSprite.position = CGPoint(x: startX + spacing * CGFloat(idx), y: -70)
            hatSprite.alpha = 0.7

            let bobUp = SKAction.moveBy(x: 0, y: 6, duration: 1.2 + Double(idx) * 0.15)
            let bobDown = SKAction.moveBy(x: 0, y: -6, duration: 1.2 + Double(idx) * 0.15)
            bobUp.timingMode = .easeInEaseOut
            bobDown.timingMode = .easeInEaseOut
            hatSprite.run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])))

            titleContainer.addChild(hatSprite)
        }

        addChild(titleContainer)
    }

    // MARK: - Menu Buttons

    private func erectorMenuButtons() {
        let centerX = size.width / 2
        let btnWidth = min(size.width - 80, 260)

        // Mode 1 - Cascade Duel
        let mode1Btn = StylizedButtonFabricator.fabricatePill(
            inscription: "btn_mode_cascade",
            extent: CGSize(width: btnWidth, height: 56),
            fillChroma: ChromaticPalette.zephyrBlue,
            cornerArc: 28,
            glyphSize: 19
        )
        if let lbl = mode1Btn.childNode(withName: "btn_mode_cascade") as? SKLabelNode {
            lbl.text = "Cascade Duel"
        }
        mode1Btn.position = CGPoint(x: centerX, y: size.height * 0.46)
        mode1Btn.name = "btn_mode_cascade"
        addChild(mode1Btn)

        // Mode 2 - Column Stack
        let mode2Btn = StylizedButtonFabricator.fabricatePill(
            inscription: "btn_mode_column",
            extent: CGSize(width: btnWidth, height: 56),
            fillChroma: ChromaticPalette.lavendelMist,
            cornerArc: 28,
            glyphSize: 19
        )
        if let lbl = mode2Btn.childNode(withName: "btn_mode_column") as? SKLabelNode {
            lbl.text = "Column Stack"
        }
        mode2Btn.position = CGPoint(x: centerX, y: size.height * 0.46 - 76)
        mode2Btn.name = "btn_mode_column"
        addChild(mode2Btn)

        // Leaderboard
        let leaderBtn = StylizedButtonFabricator.fabricatePill(
            inscription: "btn_leaderboard",
            extent: CGSize(width: btnWidth, height: 56),
            fillChroma: ChromaticPalette.amberGleam,
            cornerArc: 28,
            glyphSize: 19
        )
        if let lbl = leaderBtn.childNode(withName: "btn_leaderboard") as? SKLabelNode {
            lbl.text = "Leaderboard"
        }
        leaderBtn.position = CGPoint(x: centerX, y: size.height * 0.46 - 152)
        leaderBtn.name = "btn_leaderboard"
        addChild(leaderBtn)

        // How to Play
        let helpBtn = StylizedButtonFabricator.fabricatePill(
            inscription: "btn_howtoplay",
            extent: CGSize(width: btnWidth, height: 56),
            fillChroma: ChromaticPalette.mintDew,
            cornerArc: 28,
            glyphSize: 19
        )
        if let lbl = helpBtn.childNode(withName: "btn_howtoplay") as? SKLabelNode {
            lbl.text = "How to Play"
        }
        helpBtn.position = CGPoint(x: centerX, y: size.height * 0.46 - 228)
        helpBtn.name = "btn_howtoplay"
        addChild(helpBtn)
    }

    // MARK: - Floating Ambience

    private func erectorFloatingAmbience() {
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnFloatingCap()
        }
        let delay = SKAction.wait(forDuration: 2.5, withRange: 1.5)
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, delay])))
    }

    private func spawnFloatingCap() {
        let variant = CapVariant.stochasticPick()
        let sprite = SKSpriteNode(texture: variant.texturePlacard)
        sprite.size = CGSize(width: 28, height: 28)
        sprite.alpha = 0.15
        sprite.zPosition = -2

        let startX = CGFloat.random(in: 20...(size.width - 20))
        sprite.position = CGPoint(x: startX, y: -30)

        addChild(sprite)

        let drift = CGFloat.random(in: -40...40)
        let duration = Double.random(in: 8...14)
        let moveUp = SKAction.moveBy(x: drift, y: size.height + 60, duration: duration)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()

        sprite.run(SKAction.sequence([moveUp, fadeOut, remove]))
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        for node in tappedNodes {
            let nodeName = node.name ?? node.parent?.name

            if nodeName == "btn_mode_cascade" {
                HapticCourier.communal.emitTap()
                animateAndTransition(node: findButtonRoot(node)) {
                    self.transitionToCascadeDuel()
                }
                return
            }
            if nodeName == "btn_mode_column" {
                HapticCourier.communal.emitTap()
                animateAndTransition(node: findButtonRoot(node)) {
                    self.transitionToColumnStack()
                }
                return
            }
            if nodeName == "btn_leaderboard" {
                HapticCourier.communal.emitTap()
                animateAndTransition(node: findButtonRoot(node)) {
                    self.transitionToLeaderboard()
                }
                return
            }
            if nodeName == "btn_howtoplay" {
                HapticCourier.communal.emitTap()
                animateAndTransition(node: findButtonRoot(node)) {
                    self.presentHowToPlay()
                }
                return
            }
        }
    }

    private func findButtonRoot(_ node: SKNode) -> SKNode {
        if node.parent is SKScene || node.parent == nil { return node }
        if node.parent?.name?.hasPrefix("btn_") == true { return node.parent! }
        return node
    }

    private func animateAndTransition(node: SKNode, completion: @escaping () -> Void) {
        let shrink = SKAction.scale(to: 0.92, duration: 0.08)
        let grow = SKAction.scale(to: 1.0, duration: 0.08)
        node.run(SKAction.sequence([shrink, grow])) {
            completion()
        }
    }

    // MARK: - How to Play

    private func presentHowToPlay() {
        let paragraphs = [
            "--- CASCADE DUEL ---",
            "Hats fall from the top across 6 lanes. Each lane has a target hat shown at the bottom.",
            "Tap a falling hat to select it, then tap another hat in the same wave to swap their positions.",
            "If a hat lands on its matching target: +10 points! If it lands on the wrong target: Game Over!",
            "The falling speed increases over time. Stay sharp!",
            "",
            "--- COLUMN STACK ---",
            "Tap any of the 5 columns to drop the current hat into it. Check the preview to see your next hat.",
            "When 3 or more identical hats stack consecutively in a column, they are eliminated and you earn points.",
            "New hats rise from the bottom every 10 seconds, pushing your stack upward.",
            "The game ends when any column reaches the top. Plan ahead and stack wisely!"
        ]

        let dialog = BespokeDialogOverlay.fabricateTutorialDialog(
            sceneExtent: size,
            title: "How to Play",
            paragraphs: paragraphs,
            titleColor: ChromaticPalette.mintDew,
            onDismiss: {}
        )
        addChild(dialog)
    }

    // MARK: - Scene Transitions

    private func transitionToCascadeDuel() {
        let nextScene = CascadeDuelScene(size: self.size)
        nextScene.scaleMode = .resizeFill
        let reveal = SKTransition.push(with: .left, duration: 0.4)
        view?.presentScene(nextScene, transition: reveal)
    }

    private func transitionToColumnStack() {
        let nextScene = ColumnStackScene(size: self.size)
        nextScene.scaleMode = .resizeFill
        let reveal = SKTransition.push(with: .left, duration: 0.4)
        view?.presentScene(nextScene, transition: reveal)
    }

    private func transitionToLeaderboard() {
        let nextScene = StandingsScene(size: self.size)
        nextScene.scaleMode = .resizeFill
        let reveal = SKTransition.push(with: .left, duration: 0.4)
        view?.presentScene(nextScene, transition: reveal)
    }
}
