//
//  SoundEffectManager.swift
//  muthos
//
//  Created by shining on 2016. 12. 28..
//
//

import Foundation
import AVFoundation

enum SOUND_CODE {
    case bookOpen
    case bookClose
    case coin
    case roulette
    case bonus
    case perfect
    case excellent
    case good
    case notBad
    case bad
    case success
    case fail
    case score
    case levelUp
    case noteIn
    case noteOut
}

class SoundEffectManager {
    var map: [SOUND_CODE : AVPlayerItem] = [
        .bookOpen : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "03_01_bookopen", withExtension: "mp3")!)),
        .bookClose : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "03_02_bookclose_01", withExtension: "mp3")!)),
        .coin : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "04_01_coin", withExtension: "mp3")!)),
        .roulette : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "05_01_roulette", withExtension: "mp3")!)),
        .bonus : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "06_01_bonus", withExtension: "mp3")!)),
        .perfect : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "07_01_talk", withExtension: "mp3")!)),
        .excellent : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "07_02_talk", withExtension: "mp3")!)),
        .good : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "07_02_talk", withExtension: "mp3")!)),
        .notBad : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "07_02_talk", withExtension: "mp3")!)),
        .bad : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "07_03_talk", withExtension: "mp3")!)),
        .success : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "08_01_success", withExtension: "mp3")!)),
        .fail : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "08_02_fail", withExtension: "mp3")!)),
        .score : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "09_01_score", withExtension: "mp3")!)),
        .levelUp : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "10_01_levelup", withExtension: "mp3")!)),
        .noteIn : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "11_01_in", withExtension: "mp3")!)),
        .noteOut : AVPlayerItem(asset:AVAsset(url:Bundle.main.url(forResource: "11_02_out", withExtension: "mp3")!))
    ]
    
    let player:AVPlayer = AVPlayer()
    
    func playWith(code:SOUND_CODE) {
        guard let item = map[code] else { return }
        player.replaceCurrentItem(with: item)
        player.seek(to: CMTimeMakeWithSeconds(0,1))
        player.play()
    }
    
    func stop() {
        player.pause()
    }
}
