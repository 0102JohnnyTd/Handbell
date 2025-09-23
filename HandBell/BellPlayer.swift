//
//  BellPlayer.swift
//  HandBell
//
//  Created by GitHub Copilot.
//

import Foundation
import AVFoundation
import AudioToolbox
import UIKit

/// Simple audio player for bell sound and optional haptic feedback.
final class BellPlayer: NSObject {
    private var player: AVAudioPlayer?

    /// true にするとサイレントスイッチ中でも再生（.playback）。デフォルトは false（.ambient で他の音とミックス・サイレント尊重）。
    var overrideSilentSwitch: Bool = false

    /// 再生音量（0.0 - 1.0）。
    var volume: Float = 1.0

    /// Prepares the audio session for playback.
    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            let category: AVAudioSession.Category = overrideSilentSwitch ? .playback : .ambient
            try session.setCategory(category, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            // Ignore failures; sound just may not play
        }
    }

    /// 指定ファイル名を優先して再生。見つからない場合、`bell.(wav|mp3|aiff)` を順に探索。
    func ring(filename: String? = nil) {
        configureSession()

        let namesToTry: [String] = {
            if let filename, !filename.isEmpty { return [filename] }
            return ["bell"]
        }()
        let exts = ["wav", "mp3", "aiff", "m4a"]

        var foundURL: URL?
        for name in namesToTry {
            for ext in exts {
                if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                    foundURL = url
                    break
                }
            }
            if foundURL != nil { break }
        }

        if let url = foundURL {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.volume = volume
                player?.prepareToPlay()
                player?.play()
            } catch {
                // Fallback to a system sound if loading fails
                AudioServicesPlaySystemSound(1057) // Tink
            }
        } else {
            // No custom sound added; fallback
            AudioServicesPlaySystemSound(1057)
        }

        // Light haptic
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // Intentionally no gating or delegate-based control.
}
