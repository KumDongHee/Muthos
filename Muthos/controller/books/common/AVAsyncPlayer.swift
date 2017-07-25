//
//  AVAsyncPlayer.swift
//  muthos
//
//  Created by YoungjuneKwon on 2016. 3. 30..
//
//

import UIKit
import AVFoundation

class AVAsyncPlayer : UIView {
    var callback:Async.callbackFunc?
    var looping:Bool = false

    var contentURL:URL?
    var currentPlayerIndex:Int = 0
    var players : [AVPlayer] = []
    var playerLayers : [AVPlayerLayer] = []
    
    func prepare(_ cnt:Int) {
        var i = players.count
        repeat {
            let p:AVPlayer = AVPlayer()
            p.volume = 0.5
            players.append(p)
            i += 1
        } while i < cnt
    }
    
    func play(_ url:URL) {
        play(url, callback:{() -> Bool in return true })
    }
    
    func play(_ url:URL, callback:@escaping Async.callbackFunc) {
        prepare(1)
        currentPlayer().replaceCurrentItem(with: AVPlayerItem(url:url))
        playCurrent(callback)
    }
    
    func playCurrent(_ callback:@escaping Async.callbackFunc) {
        self.callback = callback
        currentPlayer().play()
        
        self.perform(#selector(AVAsyncPlayer.setupObserver), with: nil, afterDelay: 0.5)
    }
    
    func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(AVAsyncPlayer.onVideoEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentPlayer().currentItem)
    }
    
    func onVideoEnd(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self, name:NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentPlayer().currentItem)
        _ = self.callback!()
    }
    
    func loop(_ url:URL) {
        stop()
        self.contentURL = url
        self.looping = true
        prepare(1)
        func doLoop() {
            if !self.looping {
                return
            }
            self.switchPlayer()
            self.currentPlayer().replaceCurrentItem(with: AVPlayerItem(url:url))
            self.playCurrent({()->Bool in
                doLoop()
                return true
            })
        }
        doLoop()
    }
    
    func prepareContent(_ url:URL) {
        nextPlayer().replaceCurrentItem(with: AVPlayerItem(url:url))
        nextPlayer().currentItem!.seek(to: CMTimeMakeWithSeconds(0.0, nextPlayer().currentTime().timescale))
    }

    func stop() {
        pauseAllPlayers()
        self.looping = false
    }
    
    func currentPlayer() -> AVPlayer {
        prepare(1)
        return self.players[currentPlayerIndex]
    }
    
    func nextPlayer() -> AVPlayer {
        return self.players[(currentPlayerIndex + 1) % self.players.count]
    }
    
    func selectPlayerAtIndex(_ idx:Int) {
        prepare(1)
        pauseAllPlayers()
        currentPlayerIndex = idx % players.count
        CATransaction.setDisableActions(true)
        for (i, p) in playerLayers.enumerated() {
            if i == currentPlayerIndex {
                p.zPosition = 1
            }
            else {
                p.zPosition = 0
            }
        }
    }
    
    func switchPlayer() {
        selectPlayerAtIndex(currentPlayerIndex+1)
    }
    
    func pauseAllPlayers() {
        for p in players {
            p.pause()
        }
    }
    
    func resumeLooping() {
        for p in players { p.volume = 1.0 }
    }
    
    func doVolumeFade(callback:@escaping Async.callbackFunc) {
        let FADE:Float = 0.2
        if (currentPlayer().volume >= FADE) {
            currentPlayer().volume = currentPlayer().volume - 0.1;

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.doVolumeFade(callback: callback)
            }
        } else {
            for p in players { p.volume = FADE }
            _ = callback()
        }
    }
}
