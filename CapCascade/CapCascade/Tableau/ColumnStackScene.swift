import SpriteKit

// MARK: - Column Stack Scene (Mode 2)

final class ColumnStackScene: SKScene {

    // MARK: - Constants
    private let laneQuantity = 5
    private let topBarHeight: CGFloat = 120
    private let bottomZoneHeight: CGFloat = 60
    private let ambientSpawnInterval: TimeInterval = 10.0

    // MARK: - State
    private var isArenaActive = false
    private var isPaused_custom = false
    private var accruedPoints = 0
    private var elapsedChronometer: TimeInterval = 0
    private var lastUpdateEpoch: TimeInterval = 0
    private var ambientAccumulator: TimeInterval = 0

    // MARK: - Nodes
    private var scoreGlyph: SKLabelNode!
    private var timerGlyph: SKLabelNode!
    private var previewSprite: SKSpriteNode!
    private var previewLabel: SKLabelNode!

    // MARK: - Grid Data
    private var columnStacks: [[StackedCap]] = []
    private var pendingVariant: CapVariant = .chef
    private var nextVariant: CapVariant = .chef

    // MARK: - Dimensions (computed on layout)
    private var laneWidth: CGFloat = 0
    private var capDimension: CGFloat = 0
    private var gridOriginY: CGFloat = 0
    private var laneTopY: CGFloat = 0

    // MARK: - Stacked Cap Wrapper
    private class StackedCap {
        let sprite: SKSpriteNode
        var variant: CapVariant
        let columnIdx: Int
        var rowIdx: Int

        init(sprite: SKSpriteNode, variant: CapVariant, columnIdx: Int, rowIdx: Int) {
            self.sprite = sprite
            self.variant = variant
            self.columnIdx = columnIdx
            self.rowIdx = rowIdx
        }
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0, y: 0)
        backgroundColor = .clear

        laneWidth = DimensionalReckoner.reckonLaneWidth(laneCount: laneQuantity, sceneWidth: size.width)
        capDimension = DimensionalReckoner.reckonCapDimension(laneWidth: laneWidth)
        gridOriginY = bottomZoneHeight
        laneTopY = size.height - topBarHeight - 40

        erectorBackdrop()
        erectorScorePlacard()
        erectorPauseButton()
        erectorPreviewZone()
        erectorLanes()
        erectorColumnTapZones()
        initializeColumnStacks()

        if !UserDefaults.standard.bool(forKey: "tutorial_seen_column") {
            UserDefaults.standard.set(true, forKey: "tutorial_seen_column")
            presentTutorial()
        } else {
            commenceArena()
        }
    }

    // MARK: - Tutorial

    private func presentTutorial() {
        let paragraphs = [
            "Tap any of the 5 columns to drop the current hat into it.",
            "Check the preview at the top to see your next hat. Plan your moves!",
            "When 3 or more identical hats stack consecutively in a column, they are eliminated for points.",
            "New hats rise from the bottom every 10 seconds, pushing your stack upward.",
            "The game ends when any column reaches the top. Stack wisely!"
        ]
        let dialog = BespokeDialogOverlay.fabricateTutorialDialog(
            sceneExtent: size,
            title: "Column Stack",
            paragraphs: paragraphs,
            titleColor: ChromaticPalette.lavendelMist,
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
            upperChroma: UIColor(red: 0.92, green: 0.88, blue: 1.0, alpha: 1.0),
            lowerChroma: UIColor(red: 0.82, green: 0.78, blue: 0.96, alpha: 1.0)
        )
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(bg)
    }

    private func erectorScorePlacard() {
        let placard = ScorePlacardFabricator.fabricate(
            sceneWidth: size.width,
            yPosition: size.height - topBarHeight + 40
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
        pauseBtn.position = CGPoint(x: size.width - 35, y: size.height - topBarHeight + 70)
        pauseBtn.name = "btn_pause"
        pauseBtn.zPosition = 15
        addChild(pauseBtn)
    }

    private func erectorPreviewZone() {
        let previewBg = SKShapeNode(rectOf: CGSize(width: 160, height: 60), cornerRadius: 16)
        previewBg.fillColor = UIColor(white: 1.0, alpha: 0.25)
        previewBg.strokeColor = UIColor(white: 1.0, alpha: 0.35)
        previewBg.lineWidth = 1
        previewBg.position = CGPoint(x: size.width / 2, y: size.height - topBarHeight - 10)
        previewBg.zPosition = 10
        addChild(previewBg)

        previewLabel = SKLabelNode(text: "NEXT")
        previewLabel.fontName = "AvenirNext-DemiBold"
        previewLabel.fontSize = 12
        previewLabel.fontColor = ChromaticPalette.slateCaption
        previewLabel.position = CGPoint(x: -35, y: -4)
        previewLabel.verticalAlignmentMode = .center
        previewBg.addChild(previewLabel)

        previewSprite = SKSpriteNode()
        previewSprite.size = CGSize(width: 40, height: 40)
        previewSprite.position = CGPoint(x: 25, y: 0)
        previewBg.addChild(previewSprite)
    }

    private func erectorLanes() {
        let lanes = LaneScaffoldFabricator.fabricateLanes(
            count: laneQuantity,
            sceneExtent: size,
            topMargin: topBarHeight + 40,
            bottomMargin: bottomZoneHeight
        )
        for lane in lanes {
            addChild(lane)
        }
    }

    private func erectorColumnTapZones() {
        // Tap detection handled entirely via x-position in touchesBegan
    }

    private func initializeColumnStacks() {
        columnStacks = Array(repeating: [], count: laneQuantity)
    }

    // MARK: - Game Flow

    private func commenceArena() {
        isArenaActive = true
        isPaused_custom = false
        accruedPoints = 0
        elapsedChronometer = 0
        lastUpdateEpoch = 0
        ambientAccumulator = 0

        pendingVariant = CapVariant.stochasticPick()
        nextVariant = CapVariant.stochasticPick()
        refreshPreviewDisplay()
        refreshScoreDisplay()
    }

    private func concludeArena() {
        guard isArenaActive else { return }
        isArenaActive = false

        let ledger = TallyLedger(
            cognomen: LedgerVault.communal.retrievePatronName(),
            accruedPoints: accruedPoints,
            elapsedDuration: elapsedChronometer,
            epochStamp: Date(),
            arenaKind: .columnStack
        )
        LedgerVault.communal.inscribeLedger(ledger)

        HapticCourier.communal.emitCalamity()

        let dialog = BespokeDialogOverlay.fabricateGameOverDialog(
            sceneExtent: size,
            finalScore: accruedPoints,
            elapsedTime: elapsedChronometer,
            arenaKind: .columnStack,
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
        for col in columnStacks {
            for cap in col {
                cap.sprite.removeFromParent()
            }
        }
        columnStacks = Array(repeating: [], count: laneQuantity)
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
        guard isArenaActive else { return }

        if lastUpdateEpoch == 0 {
            lastUpdateEpoch = currentTime
            return
        }

        let deltaTime = currentTime - lastUpdateEpoch
        lastUpdateEpoch = currentTime

        guard deltaTime < 1.0 else { return }

        elapsedChronometer += deltaTime
        ambientAccumulator += deltaTime

        // Ambient spawn every 10s
        if ambientAccumulator >= ambientSpawnInterval {
            ambientAccumulator = 0
            injectAmbientRow()
        }

        refreshScoreDisplay()
    }

    // MARK: - Ambient Row Injection

    private func injectAmbientRow() {
        for colIdx in 0..<laneQuantity {
            if !wouldExceedLane(columnIdx: colIdx) {
                let variant = CapVariant.stochasticPick()
                insertCapIntoColumn(variant: variant, columnIdx: colIdx, fromAmbient: true)
            }
        }
        // Check for eliminations after ambient injection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.sweepAllColumnsForElimination()
            self?.auditForGameOver()
        }
    }

    // MARK: - Cap Placement

    private func depositCapInColumn(_ columnIdx: Int) {
        guard isArenaActive else { return }
        guard !wouldExceedLane(columnIdx: columnIdx) else {
            HapticCourier.communal.emitCalamity()
            auditForGameOver()
            return
        }

        HapticCourier.communal.emitTap()

        insertCapIntoColumn(variant: pendingVariant, columnIdx: columnIdx, fromAmbient: false)

        // Advance preview
        pendingVariant = nextVariant
        nextVariant = CapVariant.stochasticPick()
        refreshPreviewDisplay()

        // Check elimination after short delay for animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.sweepColumnForElimination(columnIdx)
            self?.auditForGameOver()
        }
    }

    private func insertCapIntoColumn(variant: CapVariant, columnIdx: Int, fromAmbient: Bool) {
        let xPos = DimensionalReckoner.reckonLaneXPosition(
            laneIndex: columnIdx, laneCount: laneQuantity, sceneWidth: size.width
        )

        let sprite = SKSpriteNode(texture: variant.texturePlacard)
        sprite.size = CGSize(width: capDimension, height: capDimension)
        sprite.zPosition = 8

        if fromAmbient {
            // Insert at bottom (row 0), push existing caps up
            let targetY = gridOriginY + capDimension / 2 + 10
            sprite.position = CGPoint(x: xPos, y: gridOriginY - 20)
            sprite.alpha = 0.0
            addChild(sprite)
            let moveUp = SKAction.move(to: CGPoint(x: xPos, y: targetY), duration: 0.35)
            moveUp.timingMode = .easeOut
            sprite.run(SKAction.group([moveUp, SKAction.fadeIn(withDuration: 0.25)]))

            let stackedCap = StackedCap(sprite: sprite, variant: variant, columnIdx: columnIdx, rowIdx: 0)
            columnStacks[columnIdx].insert(stackedCap, at: 0)
            // Reposition existing caps upward
            repositionColumn(columnIdx)
        } else {
            // Drop from top, append at the top of the stack
            let rowIdx = columnStacks[columnIdx].count
            let targetY = gridOriginY + capDimension * CGFloat(rowIdx) + capDimension / 2 + 10
            let startY = size.height - topBarHeight
            sprite.position = CGPoint(x: xPos, y: startY)
            addChild(sprite)
            let drop = SKAction.move(to: CGPoint(x: xPos, y: targetY), duration: 0.3)
            drop.timingMode = .easeIn
            let bounce = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 8, duration: 0.08),
                SKAction.moveBy(x: 0, y: -8, duration: 0.08)
            ])
            sprite.run(SKAction.sequence([drop, bounce]))

            let stackedCap = StackedCap(sprite: sprite, variant: variant, columnIdx: columnIdx, rowIdx: rowIdx)
            columnStacks[columnIdx].append(stackedCap)
        }
    }

    // MARK: - Elimination Logic

    private func sweepAllColumnsForElimination() {
        for colIdx in 0..<laneQuantity {
            sweepColumnForElimination(colIdx)
        }
    }

    private func sweepColumnForElimination(_ columnIdx: Int) {
        var didEliminate = true

        while didEliminate {
            didEliminate = false
            let stack = columnStacks[columnIdx]
            guard stack.count >= 3 else { break }

            // Find consecutive runs of 3+
            var runStart = 0
            while runStart <= stack.count - 3 {
                let baseVariant = stack[runStart].variant
                var runEnd = runStart + 1

                while runEnd < stack.count && stack[runEnd].variant == baseVariant {
                    runEnd += 1
                }

                let runLength = runEnd - runStart
                if runLength >= 3 {
                    // Eliminate this run
                    let eliminatedCaps = Array(stack[runStart..<runEnd])
                    for cap in eliminatedCaps {
                        let sparkle = SKAction.group([
                            SKAction.scale(to: 1.4, duration: 0.15),
                            SKAction.fadeOut(withDuration: 0.2)
                        ])
                        cap.sprite.run(SKAction.sequence([sparkle, SKAction.removeFromParent()]))
                    }

                    columnStacks[columnIdx].removeSubrange(runStart..<runEnd)
                    accruedPoints += runLength * 10
                    HapticCourier.communal.emitTriumph()

                    // Reposition remaining caps above
                    repositionColumn(columnIdx)
                    didEliminate = true
                    break
                } else {
                    runStart = runEnd
                }
            }
        }
    }

    private func repositionColumn(_ columnIdx: Int) {
        let xPos = DimensionalReckoner.reckonLaneXPosition(
            laneIndex: columnIdx, laneCount: laneQuantity, sceneWidth: size.width
        )
        for (rowIdx, cap) in columnStacks[columnIdx].enumerated() {
            cap.rowIdx = rowIdx
            let targetY = gridOriginY + capDimension * CGFloat(rowIdx) + capDimension / 2 + 10
            let settle = SKAction.move(to: CGPoint(x: xPos, y: targetY), duration: 0.2)
            settle.timingMode = .easeOut
            cap.sprite.run(settle)
        }
    }

    // MARK: - Game Over Check

    private func wouldExceedLane(columnIdx: Int, additionalCaps: Int = 1) -> Bool {
        let totalCaps = columnStacks[columnIdx].count + additionalCaps
        let topOfNextCap = gridOriginY + capDimension * CGFloat(totalCaps) + 10
        return topOfNextCap > laneTopY
    }

    private func auditForGameOver() {
        for colIdx in 0..<laneQuantity {
            if wouldExceedLane(columnIdx: colIdx, additionalCaps: 1) {
                concludeArena()
                return
            }
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        // Check pause
        for node in tappedNodes {
            if node.name == "btn_pause" {
                togglePauseState()
                return
            }
        }

        guard isArenaActive else { return }

        // Determine column by x position
        let colIdx = determineColumnFromX(location.x)
        if colIdx >= 0 && colIdx < laneQuantity {
            depositCapInColumn(colIdx)
        }
    }

    private func determineColumnFromX(_ x: CGFloat) -> Int {
        // Map any x position to the nearest lane
        var bestIdx = -1
        var bestDist: CGFloat = .greatestFiniteMagnitude
        for i in 0..<laneQuantity {
            let laneX = DimensionalReckoner.reckonLaneXPosition(
                laneIndex: i, laneCount: laneQuantity, sceneWidth: size.width
            )
            let dist = abs(x - laneX)
            if dist < bestDist {
                bestDist = dist
                bestIdx = i
            }
        }
        return bestIdx
    }

    // MARK: - Pause

    private func togglePauseState() {
        if isPaused_custom { return }
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

    private func refreshPreviewDisplay() {
        previewSprite?.texture = pendingVariant.texturePlacard
    }
}
