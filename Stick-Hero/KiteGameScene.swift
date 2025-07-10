//
//  StickHeroGameScene.swift
//  Stick-Hero
//
//  Created by 顾枫 on 15/6/19.
//  Copyright © 2015年 koofrank. All rights reserved.
//

import SpriteKit
import GameplayKit

class KiteGameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Nodes
    var boat: SKShapeNode!
    var kite: SKShapeNode!
    var scoreLabel: SKLabelNode!
    var charmLabel: SKLabelNode!
    var gameOverLabel: SKLabelNode?
    var restartLabel: SKLabelNode?
    
    // MARK: - Game State
    var isTouching = false
    var isGameOver = false
    var score: CGFloat = 0.0
    var charmCount: Int = 0
    var lastObstacleSpawn: TimeInterval = 0
    var lastCharmSpawn: TimeInterval = 0
    let kiteCategory: UInt32 = 0x1 << 0
    let obstacleCategory: UInt32 = 0x1 << 1
    let charmCategory: UInt32 = 0x1 << 2
    
    // MARK: - Constants
    let boatWidth: CGFloat = 80
    let boatHeight: CGFloat = 30
    let kiteSize: CGFloat = 30
    let kiteSpeed: CGFloat = 300
    let gravity: CGFloat = 400
    let obstacleWidth: CGFloat = 40
    let obstacleHeight: CGFloat = 40
    let charmSize: CGFloat = 24
    let obstacleInterval: TimeInterval = 1.2
    let charmInterval: TimeInterval = 2.5
    let scrollSpeed: CGFloat = 200
    
    // MARK: - Scene Setup
    override func didMove(to view: SKView) {
        backgroundColor = .cyan
        physicsWorld.contactDelegate = self
        setupBoatAndKite()
        setupLabels()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        // Reposition labels for new size
        scoreLabel?.position = CGPoint(x: size.width * 0.5, y: size.height * 0.92)
        charmLabel?.position = CGPoint(x: size.width * 0.5, y: size.height * 0.84)
        gameOverLabel?.position = CGPoint(x: size.width/2, y: size.height/2)
        restartLabel?.position = CGPoint(x: size.width/2, y: size.height/2 - 60)
    }
    
    func setupBoatAndKite() {
        // Boat at bottom left
        let margin: CGFloat = 24
        let marginX: CGFloat = 48
        boat = SKShapeNode(rectOf: CGSize(width: boatWidth, height: boatHeight), cornerRadius: 8)
        boat.fillColor = .brown
        boat.strokeColor = .black
        boat.position = CGPoint(x: boatWidth/2 + marginX, y: boatHeight/2 + margin)
        addChild(boat)
        
        // Kite above the boat
        kite = SKShapeNode(rectOf: CGSize(width: kiteSize, height: kiteSize))
        kite.fillColor = .red
        kite.strokeColor = .black
        kite.position = CGPoint(x: boat.position.x, y: boat.position.y + 120)
        kite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: kiteSize, height: kiteSize))
        kite.physicsBody?.isDynamic = true
        kite.physicsBody?.affectedByGravity = false
        kite.physicsBody?.categoryBitMask = kiteCategory
        kite.physicsBody?.contactTestBitMask = obstacleCategory | charmCategory
        kite.physicsBody?.collisionBitMask = 0
        addChild(kite)
        
        // Rope (visual only)
        let rope = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: boat.position)
        path.addLine(to: kite.position)
        rope.path = path
        rope.strokeColor = .gray
        rope.lineWidth = 2
        rope.name = "rope"
        addChild(rope)
    }
    
    func setupLabels() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = .black
        scoreLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.92)
        scoreLabel.text = "Score: 0"
        addChild(scoreLabel)
        
        charmLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        charmLabel.fontSize = 24
        charmLabel.fontColor = .systemPink
        charmLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.84)
        charmLabel.text = "Charms: 0"
        addChild(charmLabel)
    }
    
    // MARK: - Touch Controls
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            let location = touches.first!.location(in: self)
            if let node = self.atPoint(location) as? SKLabelNode, node.name == "restartButton" {
                restartGame()
                return
            }
        }
        isTouching = !isGameOver
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
    }
    
    var lastUpdateTime: TimeInterval = 0
    
    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        
        var dt: CGFloat = 1.0/60.0
        if lastUpdateTime > 0 {
            dt = CGFloat(currentTime - lastUpdateTime)
        }
        lastUpdateTime = currentTime
        
        // Move obstacles and charms
        for node in children {
            if node.name == "obstacle" || node.name == "charm" {
                node.position.x -= scrollSpeed * dt
                if node.position.x < -60 {
                    node.removeFromParent()
                }
            }
        }
        
        // Update kite position
        updateKite(dt: dt)
        
        // Update rope
        if let rope = childNode(withName: "rope") as? SKShapeNode {
            let path = CGMutablePath()
            path.move(to: boat.position)
            path.addLine(to: kite.position)
            rope.path = path
        }
        
        // Spawn obstacles
        if currentTime - lastObstacleSpawn > obstacleInterval {
            spawnObstacle()
            lastObstacleSpawn = currentTime
        }
        // Spawn charms
        if currentTime - lastCharmSpawn > charmInterval {
            spawnCharm()
            lastCharmSpawn = currentTime
        }
        
        // Update score
        score += scrollSpeed * dt / 100.0
        scoreLabel.text = String(format: "Score: %.0f", score)
    }
    
    func updateKite(dt: CGFloat) {
        guard let kite = kite else { return }
        var velocityY: CGFloat = 0
        // Hold to descend (move down), release to rise (move up, but slower)
        if isTouching {
            velocityY = -kiteSpeed
        } else {
            velocityY = kiteSpeed * 0.8
        }
        // Remove gravity for more direct control
        let newY = kite.position.y + velocityY * dt
        let minY = boat.position.y + boatHeight/2 + kiteSize/2 + 8
        let maxY = size.height - kiteSize/2 - 24
        kite.position.y = max(minY, min(maxY, newY))
        // Keep kite x in sync with boat
        kite.position.x = boat.position.x
    }
    
    // MARK: - Spawning
    func spawnObstacle() {
        // Spawn obstacles from the top of the boat to the top of the screen
        let minY = boat.position.y + boatHeight/2 + obstacleHeight/2
        let maxY = size.height - obstacleHeight/2 - 24
        let y = CGFloat.random(in: minY ... maxY)
        // Bird (circle)
        let node: SKShapeNode
        node = SKShapeNode(circleOfRadius: obstacleWidth/2)
        node.fillColor = .black
        node.position = CGPoint(x: size.width + 60, y: y)
        node.name = "obstacle"
        node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: obstacleWidth, height: obstacleHeight))
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = obstacleCategory
        node.physicsBody?.contactTestBitMask = kiteCategory
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    func spawnCharm() {
        let y = CGFloat.random(in: boat.position.y + 100 ... size.height - 60)
        let charm = SKShapeNode(circleOfRadius: charmSize/2)
        charm.fillColor = .systemPink
        charm.strokeColor = .magenta
        charm.position = CGPoint(x: size.width + 60, y: y)
        charm.name = "charm"
        charm.physicsBody = SKPhysicsBody(circleOfRadius: charmSize/2)
        charm.physicsBody?.isDynamic = false
        charm.physicsBody?.categoryBitMask = charmCategory
        charm.physicsBody?.contactTestBitMask = kiteCategory
        charm.physicsBody?.collisionBitMask = 0
        addChild(charm)
    }
    
    // MARK: - Collision
    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB
        if (a.categoryBitMask == kiteCategory && b.categoryBitMask == obstacleCategory) ||
            (b.categoryBitMask == kiteCategory && a.categoryBitMask == obstacleCategory) {
            gameOver()
        } else if (a.categoryBitMask == kiteCategory && b.categoryBitMask == charmCategory) {
            b.node?.removeFromParent()
            charmCount += 1
            charmLabel.text = "Charms: \(charmCount)"
        } else if (b.categoryBitMask == kiteCategory && a.categoryBitMask == charmCategory) {
            a.node?.removeFromParent()
            charmCount += 1
            charmLabel.text = "Charms: \(charmCount)"
        }
    }
    
    func gameOver() {
        isGameOver = true
        gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel?.fontSize = 40
        gameOverLabel?.fontColor = .red
        gameOverLabel?.position = CGPoint(x: size.width/2, y: size.height/2)
        gameOverLabel?.text = "Game Over!"
        if let label = gameOverLabel {
            addChild(label)
        }
        // Add restart button
        restartLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        restartLabel?.fontSize = 32
        restartLabel?.fontColor = .blue
        restartLabel?.position = CGPoint(x: size.width/2, y: size.height/2 - 60)
        restartLabel?.text = "Restart"
        restartLabel?.name = "restartButton"
        if let restart = restartLabel {
            addChild(restart)
        }
    }

    func restartGame() {
        // Remove all children and reset state
        removeAllChildren()
        isGameOver = false
        score = 0
        charmCount = 0
        lastObstacleSpawn = 0
        lastCharmSpawn = 0
        lastUpdateTime = 0
        gameOverLabel = nil
        restartLabel = nil
        setupBoatAndKite()
        setupLabels()
    }
}
