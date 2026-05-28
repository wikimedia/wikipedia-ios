import SpriteKit
import UIKit

// Snake game using Wikipedia globe assets. Tap relative to the snake's head to steer.
final class GlobeSnakeScene: SKScene {

    // MARK: - Configuration

    private let cellSize: CGFloat = 32
    private let moveInterval: TimeInterval = 0.18

    // MARK: - Grid

    private var columns: Int = 0
    private var rows: Int = 0
    private var gridOriginX: CGFloat = 0
    private var gridOriginY: CGFloat = 0

    // MARK: - Direction

    enum Direction { case up, down, left, right }
    private var direction: Direction = .right
    private var queuedDirection: Direction = .right

    // MARK: - State

    private var snake: [SIMD2<Int32>] = []
    private var foodCell: SIMD2<Int32> = .zero
    private var score: Int = 0
    private var isGameOver = false
    private var lastMoveTime: TimeInterval = 0

    // MARK: - Nodes

    private var snakeNodes: [SKSpriteNode] = []
    private var foodNode: SKSpriteNode?
    private var scoreLabel: SKLabelNode!
    private var gameOverOverlay: SKNode?

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        setupGrid()
        setupBackground()
        setupHUD()
        newGame()
    }

    // MARK: - Setup

    private func setupGrid() {
        columns = max(10, Int(size.width / cellSize))
        rows = max(10, Int(size.height / cellSize))
        gridOriginX = (size.width - CGFloat(columns) * cellSize) / 2 + cellSize / 2
        gridOriginY = cellSize * 1.5
    }

    private func setupBackground() {
        backgroundColor = SKColor(red: 0.07, green: 0.04, blue: 0.18, alpha: 1.0)

        // Subtle dot grid
        for col in 0..<columns {
            for row in 0..<rows {
                let dot = SKShapeNode(circleOfRadius: 1.5)
                dot.fillColor = .white
                dot.alpha = 0.04
                dot.strokeColor = .clear
                dot.position = screenPos(col, row)
                dot.zPosition = -10
                addChild(dot)
            }
        }
    }

    private func setupHUD() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        scoreLabel.text = "0"
        scoreLabel.fontSize = 44
        scoreLabel.fontColor = .white
        scoreLabel.alpha = 0.9
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 64)
        scoreLabel.zPosition = 20
        addChild(scoreLabel)

        let sub = SKLabelNode(fontNamed: "AvenirNext-Medium")
        sub.text = "GLOBES EATEN"
        sub.fontSize = 11
        sub.fontColor = SKColor.white.withAlphaComponent(0.4)
        sub.position = CGPoint(x: size.width / 2, y: size.height - 84)
        sub.zPosition = 20
        addChild(sub)
    }

    // MARK: - Game

    private func newGame() {
        snakeNodes.forEach { $0.removeFromParent() }
        snakeNodes = []
        foodNode?.removeFromParent()
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil

        score = 0
        scoreLabel.text = "0"
        isGameOver = false
        direction = .right
        queuedDirection = .right
        lastMoveTime = 0

        let midX = Int32(columns / 2)
        let midY = Int32(rows / 2)
        snake = [
            SIMD2<Int32>(midX, midY),
            SIMD2<Int32>(midX - 1, midY),
            SIMD2<Int32>(midX - 2, midY)
        ]

        for (i, cell) in snake.enumerated() {
            let node = makeSegmentNode(index: i, total: snake.count)
            node.position = screenPos(Int(cell.x), Int(cell.y))
            snakeNodes.append(node)
            addChild(node)
        }

        placeFood()
    }

    // MARK: - Snake Nodes

    private func makeSegmentNode(index: Int, total: Int) -> SKSpriteNode {
        let isHead = index == 0
        let symbolName: String
        let tintColor: UIColor

        if isHead {
            symbolName = "globe.americas.fill"
            tintColor = UIColor(red: 0.3, green: 0.85, blue: 1.0, alpha: 1.0)
        } else {
            let symbols = ["globe.europe.africa.fill", "globe.asia.australia.fill", "globe.americas.fill"]
            symbolName = symbols[index % symbols.count]
            let hue = 0.58 + Double(index) / Double(max(total, 10)) * 0.15
            tintColor = UIColor(hue: CGFloat(hue), saturation: 0.75, brightness: 0.95, alpha: 1.0)
        }

        let nodeSize = isHead
            ? CGSize(width: cellSize, height: cellSize)
            : CGSize(width: cellSize * 0.85, height: cellSize * 0.85)
        let node = SKSpriteNode(color: .clear, size: nodeSize)

        if let img = UIImage(systemName: symbolName) {
            node.texture = SKTexture(image: img.withTintColor(tintColor, renderingMode: .alwaysOriginal))
            node.size = nodeSize
        }

        node.zPosition = CGFloat(1000 - index)
        node.setScale(0)
        node.run(SKAction.scale(to: 1.0, duration: 0.12))
        return node
    }

    private func convertHeadToBody(_ node: SKSpriteNode, newIndex: Int, total: Int) {
        let symbols = ["globe.europe.africa.fill", "globe.asia.australia.fill", "globe.americas.fill"]
        let symbolName = symbols[newIndex % symbols.count]
        let hue = 0.58 + Double(newIndex) / Double(max(total, 10)) * 0.15
        let tintColor = UIColor(hue: CGFloat(hue), saturation: 0.75, brightness: 0.95, alpha: 1.0)

        if let img = UIImage(systemName: symbolName) {
            node.texture = SKTexture(image: img.withTintColor(tintColor, renderingMode: .alwaysOriginal))
        }
        node.size = CGSize(width: cellSize * 0.85, height: cellSize * 0.85)
        node.zPosition = CGFloat(1000 - newIndex)
    }

    // MARK: - Food

    private func placeFood() {
        var pos: SIMD2<Int32>
        repeat {
            pos = SIMD2<Int32>(
                Int32.random(in: 1..<Int32(columns - 1)),
                Int32.random(in: 2..<Int32(rows - 3))
            )
        } while snake.contains(pos)
        foodCell = pos

        let nodeSize = CGSize(width: cellSize * 1.1, height: cellSize * 1.1)
        let node = SKSpriteNode(color: .clear, size: nodeSize)

        if let img = UIImage(named: "ftux-puzzle-globe") {
            node.texture = SKTexture(image: img)
        } else if let img = UIImage(systemName: "globe") {
            let tinted = img.withTintColor(
                UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0),
                renderingMode: .alwaysOriginal
            )
            node.texture = SKTexture(image: tinted)
        }

        node.position = screenPos(Int(pos.x), Int(pos.y))
        node.zPosition = 5

        node.setScale(0)
        let appear = SKAction.scale(to: 1.0, duration: 0.2)
        appear.timingMode = .easeOut
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.65),
            SKAction.scale(to: 0.9, duration: 0.65)
        ]))
        node.run(SKAction.sequence([appear, pulse]))

        foodNode?.removeFromParent()
        foodNode = node
        addChild(node)
    }

    // MARK: - Coordinates

    private func screenPos(_ col: Int, _ row: Int) -> CGPoint {
        CGPoint(
            x: gridOriginX + CGFloat(col) * cellSize,
            y: gridOriginY + CGFloat(row) * cellSize
        )
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        if lastMoveTime == 0 { lastMoveTime = currentTime; return }
        guard currentTime - lastMoveTime >= moveInterval else { return }
        lastMoveTime = currentTime
        step()
    }

    private func step() {
        direction = queuedDirection

        let head = snake[0]
        let next: SIMD2<Int32>
        switch direction {
        case .up:    next = SIMD2<Int32>(head.x, head.y + 1)
        case .down:  next = SIMD2<Int32>(head.x, head.y - 1)
        case .left:  next = SIMD2<Int32>(head.x - 1, head.y)
        case .right: next = SIMD2<Int32>(head.x + 1, head.y)
        }

        // Wall collision
        guard next.x >= 0, next.x < Int32(columns),
              next.y >= 0, next.y < Int32(rows) else {
            triggerGameOver()
            return
        }

        // Self-collision (tail is vacating its cell, so we skip it)
        if snake.dropLast().contains(next) {
            triggerGameOver()
            return
        }

        let ateFood = next == foodCell

        // New head node
        let headNode = makeSegmentNode(index: 0, total: snakeNodes.count + 1)
        headNode.position = screenPos(Int(next.x), Int(next.y))
        addChild(headNode)

        // Old head becomes first body segment
        convertHeadToBody(snakeNodes[0], newIndex: 1, total: snakeNodes.count + 1)

        snakeNodes.insert(headNode, at: 0)
        snake.insert(next, at: 0)

        if ateFood {
            score += 1
            scoreLabel.text = "\(score)"
            let pop = SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.07),
                SKAction.scale(to: 1.0, duration: 0.07)
            ])
            scoreLabel.run(pop)
            spawnEatParticles(at: screenPos(Int(foodCell.x), Int(foodCell.y)))
            placeFood()
        } else {
            let tail = snakeNodes.removeLast()
            snake.removeLast()
            tail.run(SKAction.sequence([
                SKAction.scale(to: 0, duration: 0.1),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - Effects

    private func spawnEatParticles(at position: CGPoint) {
        let colors: [SKColor] = [.yellow, .cyan, .magenta, .green,
                                  SKColor(red: 1, green: 0.5, blue: 0, alpha: 1)]
        for _ in 0..<10 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            spark.fillColor = colors.randomElement()!
            spark.strokeColor = .clear
            spark.position = position
            spark.zPosition = 50
            addChild(spark)

            let move = SKAction.moveBy(
                x: CGFloat.random(in: -55...55),
                y: CGFloat.random(in: -55...55),
                duration: 0.45
            )
            move.timingMode = .easeOut
            spark.run(SKAction.sequence([
                SKAction.group([move, SKAction.fadeOut(withDuration: 0.45)]),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - Game Over

    private func triggerGameOver() {
        isGameOver = true

        for (i, node) in snakeNodes.enumerated() {
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.04),
                SKAction.group([
                    SKAction.moveBy(
                        x: CGFloat.random(in: -60...60),
                        y: CGFloat.random(in: -60...60),
                        duration: 0.35
                    ),
                    SKAction.fadeOut(withDuration: 0.35),
                    SKAction.scale(to: 0.1, duration: 0.35)
                ]),
                .removeFromParent()
            ]))
        }

        let overlay = SKNode()
        overlay.zPosition = 100
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.alpha = 0

        let panel = SKShapeNode(
            rect: CGRect(x: -140, y: -85, width: 280, height: 170),
            cornerRadius: 24
        )
        panel.fillColor = SKColor(red: 0.07, green: 0.04, blue: 0.22, alpha: 0.96)
        panel.strokeColor = SKColor.white.withAlphaComponent(0.12)
        panel.lineWidth = 1
        overlay.addChild(panel)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = "GAME OVER"
        titleLabel.fontSize = 28
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 38)
        overlay.addChild(titleLabel)

        let globeIcon = SKSpriteNode(color: .clear, size: CGSize(width: 28, height: 28))
        if let img = UIImage(named: "ftux-puzzle-globe") {
            globeIcon.texture = SKTexture(image: img)
        }
        globeIcon.position = CGPoint(x: -54, y: 4)
        overlay.addChild(globeIcon)

        let countLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        countLabel.text = "\(score) globe\(score == 1 ? "" : "s") eaten"
        countLabel.fontSize = 16
        countLabel.fontColor = SKColor.white.withAlphaComponent(0.7)
        countLabel.position = CGPoint(x: 14, y: 0)
        overlay.addChild(countLabel)

        let hint = SKLabelNode(fontNamed: "AvenirNext-Regular")
        hint.text = "tap to try again"
        hint.fontSize = 13
        hint.fontColor = SKColor.white.withAlphaComponent(0.35)
        hint.position = CGPoint(x: 0, y: -42)
        overlay.addChild(hint)

        addChild(overlay)
        gameOverOverlay = overlay

        overlay.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.fadeIn(withDuration: 0.3)
        ]))
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if isGameOver {
            newGame()
            return
        }

        let loc = touch.location(in: self)
        let headPos = screenPos(Int(snake[0].x), Int(snake[0].y))
        let dx = loc.x - headPos.x
        let dy = loc.y - headPos.y

        // Choose cardinal direction based on dominant axis from snake head
        let candidate: Direction
        if abs(dx) >= abs(dy) {
            candidate = dx > 0 ? .right : .left
        } else {
            candidate = dy > 0 ? .up : .down
        }

        let isReverse: Bool
        switch (direction, candidate) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            isReverse = true
        default:
            isReverse = false
        }

        if !isReverse {
            queuedDirection = candidate
        }
    }
}
