import SpriteKit

// MARK: - Cascade Duel Scene (Mode 1)

final class CascadeDuelScene: SKScene {

    // MARK: - Constants
    private let laneQuantity = 6
    private let topBarHeight: CGFloat = 100
    private let bottomZoneHeight: CGFloat = 130

    // MARK: - State
    private var isArenaActive = false
    private var isPaused_custom = false
    private var accruedPoints = 0
    private var elapsedChronometer: TimeInterval = 0
    private var lastUpdateEpoch: TimeInterval = 0
    private var spawnCadence: TimeInterval = 3.5
    private var descendVelocity: CGFloat = 40.0
    private var difficultyEscalation: TimeInterval = 0

    // MARK: - Nodes
    private var scoreGlyph: SKLabelNode!
    private var timerGlyph: SKLabelNode!
    private var targetSentinels: [SKSpriteNode] = []
    private var activePlummets: [PlummetingCap] = []
    private var selectedPlummet: PlummetingCap?
    private var laneAssignments: [CapVariant] = []

    // MARK: - Spawn Timer
    private var spawnAccumulator: TimeInterval = 0

    // MARK: - Plummeting Cap Wrapper
    private class PlummetingCap {
        let sprite: SKSpriteNode
        var variant: CapVariant
        var laneIndex: Int
        var isDescending = true
        let waveId: Int

        init(sprite: SKSpriteNode, variant: CapVariant, laneIndex: Int, waveId: Int) {
            self.sprite = sprite
            self.variant = variant
            self.laneIndex = laneIndex
            self.waveId = waveId
        }
    }

    private var currentWaveId = 0

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0, y: 0)
        backgroundColor = .clear
        erectorBackdrop()
        erectorScorePlacard()
        erectorPauseButton()
        erectorLanes()
        erectorTargetSentinels()

        if !UserDefaults.standard.bool(forKey: "tutorial_seen_cascade") {
            UserDefaults.standard.set(true, forKey: "tutorial_seen_cascade")
            presentTutorial()
        } else {
            commenceArena()
        }
    }

    // MARK: - Tutorial

    private func presentTutorial() {
        let paragraphs = [
            "Hats fall from the top across 6 lanes.",
            "Each lane has a target hat at the bottom. Your goal is to match falling hats to their targets.",
            "Tap a falling hat to select it, then tap another hat in the same wave to swap them.",
            "Correct match: +10 pts. Wrong match: Game Over!",
            "Speed increases over time. Good luck!"
        ]
        let dialog = BespokeDialogOverlay.fabricateTutorialDialog(
            sceneExtent: size,
            title: "Cascade Duel",
            paragraphs: paragraphs,
            titleColor: ChromaticPalette.zephyrBlue,
            onDismiss: { [weak self] in
                self?.commenceArena()
            }
        )
        addChild(dialog)
    }

    // MARK: - Setup

    private func erectorBackdrop() {
        let bg = GradientFabricator.fabricateBackdrop(
            extent: size,
            upperChroma: UIColor(red: 0.90, green: 0.94, blue: 1.0, alpha: 1.0),
            lowerChroma: UIColor(red: 0.78, green: 0.85, blue: 0.98, alpha: 1.0)
        )
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(bg)
    }

    private func erectorScorePlacard() {
        let placard = ScorePlacardFabricator.fabricate(
            sceneWidth: size.width,
            yPosition: size.height - topBarHeight + 20
        )
        addChild(placard.container)
        scoreGlyph = placard.scoreLabel
        timerGlyph = placard.timerLabel
    }

    private func erectorPauseButton() {
        let pauseBtn = SKLabelNode(text: "| |")
        pauseBtn.fontName = "AvenirNext-Bold"
        pauseBtn.fontSize = 22
        pauseBtn.fontColor = ChromaticPalette.obsidianText
        pauseBtn.position = CGPoint(x: size.width - 35, y: size.height - topBarHeight + 50)
        pauseBtn.name = "btn_pause"
        pauseBtn.zPosition = 15
        addChild(pauseBtn)
    }

    private func erectorLanes() {
        let lanes = LaneScaffoldFabricator.fabricateLanes(
            count: laneQuantity,
            sceneExtent: size,
            topMargin: topBarHeight,
            bottomMargin: bottomZoneHeight
        )
        for lane in lanes {
            addChild(lane)
        }
    }

    private func erectorTargetSentinels() {
        var allVariants = CapVariant.allCases.shuffled()
        laneAssignments = Array(allVariants.prefix(laneQuantity))

        let capDim = DimensionalReckoner.reckonCapDimension(
            laneWidth: DimensionalReckoner.reckonLaneWidth(laneCount: laneQuantity, sceneWidth: size.width)
        )

        for i in 0..<laneQuantity {
            let xPos = DimensionalReckoner.reckonLaneXPosition(
                laneIndex: i, laneCount: laneQuantity, sceneWidth: size.width
            )
            let sentinel = SKSpriteNode(texture: laneAssignments[i].texturePlacard)
            sentinel.size = CGSize(width: capDim, height: capDim)
            sentinel.position = CGPoint(x: xPos, y: bottomZoneHeight - 20)
            sentinel.alpha = 0.45
            sentinel.zPosition = 2
            sentinel.name = "sentinel_\(i)"

            // Glowing ring beneath
            let halo = SKShapeNode(circleOfRadius: capDim / 2 + 4)
            halo.strokeColor = ChromaticPalette.zephyrBlue.withAlphaComponent(0.4)
            halo.lineWidth = 2
            halo.fillColor = .clear
            halo.position = CGPoint.zero
            halo.zPosition = -1
            sentinel.addChild(halo)

            addChild(sentinel)
            targetSentinels.append(sentinel)
        }
    }

    // MARK: - Game Flow

    private func commenceArena() {
        isArenaActive = true
        isPaused_custom = false
        accruedPoints = 0
        elapsedChronometer = 0
        lastUpdateEpoch = 0
        spawnAccumulator = 0
        difficultyEscalation = 0
        currentWaveId = 0
        refreshScoreDisplay()
    }

    private func concludeArena() {
        guard isArenaActive else { return }
        isArenaActive = false

        // Save record
        let ledger = TallyLedger(
            cognomen: LedgerVault.communal.retrievePatronName(),
            accruedPoints: accruedPoints,
            elapsedDuration: elapsedChronometer,
            epochStamp: Date(),
            arenaKind: .cascadeDuel
        )
        LedgerVault.communal.inscribeLedger(ledger)

        HapticCourier.communal.emitCalamity()

        // Show game over dialog
        let dialog = BespokeDialogOverlay.fabricateGameOverDialog(
            sceneExtent: size,
            finalScore: accruedPoints,
            elapsedTime: elapsedChronometer,
            arenaKind: .cascadeDuel,
            onReplay: { [weak self] in
                self?.resetArena()
            },
            onEgress: { [weak self] in
                self?.retreatToVestibule()
            }
        )
        addChild(dialog)
    }

    private func resetArena() {
        // Remove all falling caps
        for plummet in activePlummets {
            plummet.sprite.removeFromParent()
        }
        activePlummets.removeAll()
        selectedPlummet = nil

        // Reassign targets
        for sentinel in targetSentinels {
            sentinel.removeFromParent()
        }
        targetSentinels.removeAll()
        erectorTargetSentinels()

        commenceArena()
    }

    private func retreatToVestibule() {
        let menuScene = VestibuleScene(size: self.size)
        menuScene.scaleMode = .resizeFill
        let reveal = SKTransition.push(with: .right, duration: 0.4)
        view?.presentScene(menuScene, transition: reveal)
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard isArenaActive, !isPaused_custom else { return }

        if lastUpdateEpoch == 0 {
            lastUpdateEpoch = currentTime
            return
        }

        let deltaTime = currentTime - lastUpdateEpoch
        lastUpdateEpoch = currentTime

        // Guard against huge delta (e.g. returning from background)
        guard deltaTime < 1.0 else { return }

        elapsedChronometer += deltaTime
        spawnAccumulator += deltaTime
        difficultyEscalation += deltaTime

        // Escalate difficulty
        escalateDifficulty()

        // Spawn new caps
        if spawnAccumulator >= spawnCadence {
            spawnAccumulator = 0
            spawnPlummetingCap()
        }

        // Move falling caps
        advancePlummets(deltaTime: deltaTime)

        refreshScoreDisplay()
    }

    private func escalateDifficulty() {
        // Every 15 seconds, increase speed and spawn rate
        if difficultyEscalation > 15 {
            difficultyEscalation = 0
            descendVelocity = min(descendVelocity + 8, 160)
            spawnCadence = max(spawnCadence - 0.15, 1.2)
        }
    }

    // MARK: - Spawning

    private func spawnPlummetingCap() {
        let laneWidth = DimensionalReckoner.reckonLaneWidth(laneCount: laneQuantity, sceneWidth: size.width)
        let capDim = DimensionalReckoner.reckonCapDimension(laneWidth: laneWidth)

        currentWaveId += 1
        // Shuffle all 6 lane assignments to ensure each lane gets a unique variant
        let variants = laneAssignments.shuffled()

        for laneIndex in 0..<laneQuantity {
            let variant = variants[laneIndex]
            let xPos = DimensionalReckoner.reckonLaneXPosition(
                laneIndex: laneIndex, laneCount: laneQuantity, sceneWidth: size.width
            )

            let sprite = SKSpriteNode(texture: variant.texturePlacard)
            sprite.size = CGSize(width: capDim, height: capDim)
            sprite.position = CGPoint(x: xPos, y: size.height - topBarHeight - 10)
            sprite.zPosition = 5
            sprite.name = "plummet_\(activePlummets.count)"

            addChild(sprite)

            let plummet = PlummetingCap(sprite: sprite, variant: variant, laneIndex: laneIndex, waveId: currentWaveId)
            activePlummets.append(plummet)
        }
    }

    // MARK: - Movement & Collision

    private func advancePlummets(deltaTime: TimeInterval) {
        var toRemove: [Int] = []

        for (index, plummet) in activePlummets.enumerated() {
            guard plummet.isDescending else { continue }

            let newY = plummet.sprite.position.y - descendVelocity * CGFloat(deltaTime)
            plummet.sprite.position.y = newY

            // Check if reached bottom zone
            if newY <= bottomZoneHeight {
                plummet.isDescending = false
                adjudicateArrival(plummet: plummet)
                toRemove.append(index)
            }
        }

        // Remove arrived caps (reverse order to maintain indices)
        for index in toRemove.reversed() {
            if index < activePlummets.count {
                activePlummets.remove(at: index)
            }
        }
    }

    private func adjudicateArrival(plummet: PlummetingCap) {
        let targetVariant = laneAssignments[plummet.laneIndex]

        if plummet.variant == targetVariant {
            // Match success
            accruedPoints += 10
            HapticCourier.communal.emitTriumph()
            animateMatchSuccess(sprite: plummet.sprite)
        } else {
            // Mismatch - game over
            animateMatchFailure(sprite: plummet.sprite) { [weak self] in
                self?.concludeArena()
            }
        }
    }

    // MARK: - Match Animations

    private func animateMatchSuccess(sprite: SKSpriteNode) {
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.12)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()

        // Sparkle effect
        let sparkle = SKShapeNode(circleOfRadius: 20)
        sparkle.fillColor = ChromaticPalette.amberGleam
        sparkle.strokeColor = .clear
        sparkle.alpha = 0.6
        sparkle.position = sprite.position
        sparkle.zPosition = 4
        addChild(sparkle)

        sparkle.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.5, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))

        // +10 floating text
        let pointLabel = SKLabelNode(text: "+10")
        pointLabel.fontName = "AvenirNext-Bold"
        pointLabel.fontSize = 22
        pointLabel.fontColor = ChromaticPalette.mintDew
        pointLabel.position = CGPoint(x: sprite.position.x, y: sprite.position.y + 20)
        pointLabel.zPosition = 20
        addChild(pointLabel)

        pointLabel.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 50, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            SKAction.removeFromParent()
        ]))

        sprite.run(SKAction.sequence([scaleUp, fadeOut, remove]))
    }

    private func animateMatchFailure(sprite: SKSpriteNode, completion: @escaping () -> Void) {
        let shake1 = SKAction.moveBy(x: -8, y: 0, duration: 0.05)
        let shake2 = SKAction.moveBy(x: 16, y: 0, duration: 0.05)
        let shake3 = SKAction.moveBy(x: -8, y: 0, duration: 0.05)
        let tint = SKAction.colorize(with: .red, colorBlendFactor: 0.7, duration: 0.15)

        // X mark
        let xMark = SKLabelNode(text: "X")
        xMark.fontName = "AvenirNext-Bold"
        xMark.fontSize = 36
        xMark.fontColor = ChromaticPalette.coralEmber
        xMark.position = sprite.position
        xMark.zPosition = 20
        xMark.alpha = 0
        addChild(xMark)

        xMark.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))

        sprite.run(SKAction.sequence([
            SKAction.group([
                SKAction.sequence([shake1, shake2, shake3, shake1, shake2, shake3]),
                tint
            ]),
            SKAction.wait(forDuration: 0.4)
        ])) {
            sprite.removeFromParent()
            completion()
        }
    }

    // MARK: - Touch Handling (Swap Mechanic)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        // Check pause button
        for node in tappedNodes {
            if node.name == "btn_pause" {
                togglePauseState()
                return
            }
        }

        guard isArenaActive, !isPaused_custom else { return }

        // Find tapped falling cap
        for plummet in activePlummets where plummet.isDescending {
            if plummet.sprite.contains(location) {
                handlePlummetSelection(plummet)
                return
            }
        }
    }

    private func handlePlummetSelection(_ plummet: PlummetingCap) {
        if let existing = selectedPlummet {
            if existing.sprite === plummet.sprite {
                // Deselect
                deselectPlummet(existing)
                selectedPlummet = nil
            } else if existing.waveId != plummet.waveId {
                // Different wave — switch selection to the new one
                deselectPlummet(existing)
                selectedPlummet = plummet
                highlightPlummet(plummet)
                HapticCourier.communal.emitTap()
            } else {
                // Same wave — swap the two
                executeSwap(first: existing, second: plummet)
                selectedPlummet = nil
            }
        } else {
            // First selection
            selectedPlummet = plummet
            highlightPlummet(plummet)
            HapticCourier.communal.emitTap()
        }
    }

    private func highlightPlummet(_ plummet: PlummetingCap) {
        let glow = SKShapeNode(circleOfRadius: plummet.sprite.size.width / 2 + 5)
        glow.strokeColor = ChromaticPalette.amberGleam
        glow.lineWidth = 3
        glow.fillColor = ChromaticPalette.amberGleam.withAlphaComponent(0.15)
        glow.name = "selection_glow"
        glow.zPosition = -1
        plummet.sprite.addChild(glow)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        glow.run(SKAction.repeatForever(pulse))
    }

    private func deselectPlummet(_ plummet: PlummetingCap) {
        plummet.sprite.childNode(withName: "selection_glow")?.removeFromParent()
    }

    private func executeSwap(first: PlummetingCap, second: PlummetingCap) {
        HapticCourier.communal.emitThud()

        // Remove highlights
        deselectPlummet(first)
        deselectPlummet(second)

        // Pause descent during swap animation
        first.isDescending = false
        second.isDescending = false

        // Swap lane indices
        let tempLane = first.laneIndex
        first.laneIndex = second.laneIndex
        second.laneIndex = tempLane

        // Compensate for descent during animation
        let swapDuration: TimeInterval = 0.18
        let fallOffset = descendVelocity * CGFloat(swapDuration)

        // Capture full target positions (x from lane, y from the other cap minus fall compensation)
        let firstTargetX = DimensionalReckoner.reckonLaneXPosition(
            laneIndex: first.laneIndex, laneCount: laneQuantity, sceneWidth: size.width
        )
        let secondTargetX = DimensionalReckoner.reckonLaneXPosition(
            laneIndex: second.laneIndex, laneCount: laneQuantity, sceneWidth: size.width
        )
        let firstTargetY = second.sprite.position.y - fallOffset
        let secondTargetY = first.sprite.position.y - fallOffset

        // Animate full position swap, then resume descent
        let moveFirst = SKAction.move(to: CGPoint(x: firstTargetX, y: firstTargetY), duration: swapDuration)
        let moveSecond = SKAction.move(to: CGPoint(x: secondTargetX, y: secondTargetY), duration: swapDuration)
        moveFirst.timingMode = .easeInEaseOut
        moveSecond.timingMode = .easeInEaseOut

        first.sprite.run(moveFirst) { first.isDescending = true }
        second.sprite.run(moveSecond) { second.isDescending = true }
    }

    // MARK: - Pause

    private func togglePauseState() {
        if isPaused_custom {
            return
        }
        isPaused_custom = true
        isArenaActive = false

        let dialog = BespokeDialogOverlay.fabricatePauseDialog(
            sceneExtent: size,
            onResume: { [weak self] in
                self?.isPaused_custom = false
                self?.isArenaActive = true
                self?.lastUpdateEpoch = 0
            },
            onEgress: { [weak self] in
                self?.retreatToVestibule()
            }
        )
        addChild(dialog)
    }

    // MARK: - Display Refresh

    private func refreshScoreDisplay() {
        scoreGlyph?.text = "Score: \(accruedPoints)"
        let minutes = Int(elapsedChronometer) / 60
        let seconds = Int(elapsedChronometer) % 60
        timerGlyph?.text = String(format: "%02d:%02d", minutes, seconds)
    }
}
