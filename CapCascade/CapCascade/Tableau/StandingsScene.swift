import SpriteKit

// MARK: - Standings Scene (Leaderboard)

final class StandingsScene: SKScene {

    private let topBarHeight: CGFloat = 100
    private let rowHeight: CGFloat = 44
    private let maxVisibleEntries = 10

    private var selectedArena: TallyLedger.ArenaKind = .cascadeDuel
    private var entriesContainer: SKNode!

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0, y: 0)
        backgroundColor = .clear
        erectorBackdrop()
        erectorHeader()
        erectorSegmentToggle()
        erectorEntriesContainer()
        erectorBackButton()
        populateEntries()
    }

    // MARK: - Setup

    private func erectorBackdrop() {
        let bg = GradientFabricator.fabricateBackdrop(
            extent: size,
            upperChroma: UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0),
            lowerChroma: UIColor(red: 0.88, green: 0.84, blue: 0.76, alpha: 1.0)
        )
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(bg)
    }

    private func erectorHeader() {
        let titleLabel = SKLabelNode(text: "Leaderboard")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 28
        titleLabel.fontColor = ChromaticPalette.obsidianText
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - topBarHeight + 30)
        titleLabel.zPosition = 10
        addChild(titleLabel)
    }

    private func erectorSegmentToggle() {
        let centerX = size.width / 2
        let segY = size.height - topBarHeight - 30
        let segWidth = min(size.width - 60, 300)
        let halfWidth = segWidth / 2

        // Cascade Duel tab
        let cascadeTab = SKShapeNode(rectOf: CGSize(width: halfWidth, height: 40), cornerRadius: 12)
        cascadeTab.fillColor = ChromaticPalette.zephyrBlue
        cascadeTab.strokeColor = .clear
        cascadeTab.position = CGPoint(x: centerX - halfWidth / 2, y: segY)
        cascadeTab.zPosition = 10
        cascadeTab.name = "tab_cascade"
        addChild(cascadeTab)

        let cascadeLabel = SKLabelNode(text: "Cascade Duel")
        cascadeLabel.fontName = "AvenirNext-DemiBold"
        cascadeLabel.fontSize = 14
        cascadeLabel.fontColor = ChromaticPalette.ivoryText
        cascadeLabel.verticalAlignmentMode = .center
        cascadeLabel.name = "tab_cascade"
        cascadeTab.addChild(cascadeLabel)

        // Column Stack tab
        let columnTab = SKShapeNode(rectOf: CGSize(width: halfWidth, height: 40), cornerRadius: 12)
        columnTab.fillColor = UIColor(white: 1.0, alpha: 0.3)
        columnTab.strokeColor = .clear
        columnTab.position = CGPoint(x: centerX + halfWidth / 2, y: segY)
        columnTab.zPosition = 10
        columnTab.name = "tab_column"
        addChild(columnTab)

        let columnLabel = SKLabelNode(text: "Column Stack")
        columnLabel.fontName = "AvenirNext-DemiBold"
        columnLabel.fontSize = 14
        columnLabel.fontColor = ChromaticPalette.obsidianText
        columnLabel.verticalAlignmentMode = .center
        columnLabel.name = "tab_column"
        columnTab.addChild(columnLabel)
    }

    private func erectorEntriesContainer() {
        entriesContainer = SKNode()
        entriesContainer.zPosition = 10
        addChild(entriesContainer)
    }

    private func erectorBackButton() {
        let backBtn = StylizedButtonFabricator.fabricatePill(
            inscription: "btn_back",
            extent: CGSize(width: 140, height: 44),
            fillChroma: ChromaticPalette.slateCaption,
            cornerArc: 22,
            glyphSize: 16
        )
        if let lbl = backBtn.childNode(withName: "btn_back") as? SKLabelNode {
            lbl.text = "Back"
        }
        backBtn.position = CGPoint(x: size.width / 2, y: 50)
        backBtn.name = "btn_back"
        backBtn.zPosition = 10
        addChild(backBtn)
    }

    // MARK: - Populate

    private func populateEntries() {
        entriesContainer.removeAllChildren()

        let ledgers = LedgerVault.communal.fetchLedgers(forArena: selectedArena)
        let topEntries = Array(ledgers.prefix(maxVisibleEntries))

        let startY = size.height - topBarHeight - 90

        if topEntries.isEmpty {
            let emptyLabel = SKLabelNode(text: "No records yet")
            emptyLabel.fontName = "AvenirNext-Medium"
            emptyLabel.fontSize = 18
            emptyLabel.fontColor = ChromaticPalette.slateCaption
            emptyLabel.verticalAlignmentMode = .center
            emptyLabel.position = CGPoint(x: size.width / 2, y: startY - 100)
            entriesContainer.addChild(emptyLabel)
            return
        }

        for (idx, ledger) in topEntries.enumerated() {
            let rowY = startY - CGFloat(idx) * rowHeight

            // Row background
            let rowBg = SKShapeNode(rectOf: CGSize(width: size.width - 40, height: rowHeight - 4), cornerRadius: 10)
            rowBg.fillColor = UIColor(white: 1.0, alpha: idx % 2 == 0 ? 0.35 : 0.2)
            rowBg.strokeColor = .clear
            rowBg.position = CGPoint(x: size.width / 2, y: rowY)
            entriesContainer.addChild(rowBg)

            // Rank
            let rankLabel = SKLabelNode(text: "#\(idx + 1)")
            rankLabel.fontName = "AvenirNext-Bold"
            rankLabel.fontSize = 16
            rankLabel.fontColor = idx < 3 ? ChromaticPalette.amberGleam : ChromaticPalette.obsidianText
            rankLabel.horizontalAlignmentMode = .left
            rankLabel.verticalAlignmentMode = .center
            rankLabel.position = CGPoint(x: 30, y: rowY)
            entriesContainer.addChild(rankLabel)

            // Name
            let nameLabel = SKLabelNode(text: ledger.cognomen)
            nameLabel.fontName = "AvenirNext-Medium"
            nameLabel.fontSize = 15
            nameLabel.fontColor = ChromaticPalette.obsidianText
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.verticalAlignmentMode = .center
            nameLabel.position = CGPoint(x: 70, y: rowY)
            entriesContainer.addChild(nameLabel)

            // Score
            let scoreLabel = SKLabelNode(text: "\(ledger.accruedPoints) pts")
            scoreLabel.fontName = "AvenirNext-DemiBold"
            scoreLabel.fontSize = 15
            scoreLabel.fontColor = ChromaticPalette.zephyrBlue
            scoreLabel.horizontalAlignmentMode = .right
            scoreLabel.verticalAlignmentMode = .center
            scoreLabel.position = CGPoint(x: size.width - 30, y: rowY)
            entriesContainer.addChild(scoreLabel)

            // Time
            let minutes = Int(ledger.elapsedDuration) / 60
            let seconds = Int(ledger.elapsedDuration) % 60
            let timeLabel = SKLabelNode(text: String(format: "%02d:%02d", minutes, seconds))
            timeLabel.fontName = "AvenirNext-Medium"
            timeLabel.fontSize = 13
            timeLabel.fontColor = ChromaticPalette.slateCaption
            timeLabel.horizontalAlignmentMode = .right
            timeLabel.verticalAlignmentMode = .center
            timeLabel.position = CGPoint(x: size.width - 100, y: rowY)
            entriesContainer.addChild(timeLabel)
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        for node in tappedNodes {
            let name = node.name ?? node.parent?.name

            if name == "tab_cascade" {
                switchToArena(.cascadeDuel)
                return
            }
            if name == "tab_column" {
                switchToArena(.columnStack)
                return
            }
            if name == "btn_back" {
                HapticCourier.communal.emitTap()
                retreatToVestibule()
                return
            }
        }
    }

    private func switchToArena(_ arena: TallyLedger.ArenaKind) {
        guard arena != selectedArena else { return }
        selectedArena = arena
        HapticCourier.communal.emitTap()
        refreshTabAppearance()
        populateEntries()
    }

    private func refreshTabAppearance() {
        if let cascadeTab = childNode(withName: "tab_cascade") as? SKShapeNode,
           let columnTab = childNode(withName: "tab_column") as? SKShapeNode {
            if selectedArena == .cascadeDuel {
                cascadeTab.fillColor = ChromaticPalette.zephyrBlue
                (cascadeTab.children.first as? SKLabelNode)?.fontColor = ChromaticPalette.ivoryText
                columnTab.fillColor = UIColor(white: 1.0, alpha: 0.3)
                (columnTab.children.first as? SKLabelNode)?.fontColor = ChromaticPalette.obsidianText
            } else {
                cascadeTab.fillColor = UIColor(white: 1.0, alpha: 0.3)
                (cascadeTab.children.first as? SKLabelNode)?.fontColor = ChromaticPalette.obsidianText
                columnTab.fillColor = ChromaticPalette.lavendelMist
                (columnTab.children.first as? SKLabelNode)?.fontColor = ChromaticPalette.ivoryText
            }
        }
    }

    private func retreatToVestibule() {
        let menuScene = VestibuleScene(size: self.size)
        menuScene.scaleMode = .resizeFill
        let reveal = SKTransition.push(with: .right, duration: 0.4)
        view?.presentScene(menuScene, transition: reveal)
    }
}
