//
//  GameViewController.swift
//  Stick-Hero
//
//  Created by 顾枫 on 15/6/19.
//  Copyright (c) 2015年 koofrank. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
    var musicPlayer:AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = self.view as! SKView
        let sceneSize = skView.bounds.size
        let scene = KiteGameScene(size: sceneSize)
        scene.scaleMode = .resizeFill
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        musicPlayer = setupAudioPlayerWithFile("bg_country", type: "mp3")
        musicPlayer.numberOfLoops = -1
        musicPlayer.play()
    }
    
    
    func setupAudioPlayerWithFile(_ file:NSString, type:NSString) -> AVAudioPlayer  {
        let url = Bundle.main.url(forResource: file as String, withExtension: type as String)
        var audioPlayer:AVAudioPlayer?
        
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: url!)
        } catch {
            print("NO AUDIO PLAYER")
        }
        
        return audioPlayer!
    }


    override var shouldAutorotate : Bool {
        return true
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }
}
