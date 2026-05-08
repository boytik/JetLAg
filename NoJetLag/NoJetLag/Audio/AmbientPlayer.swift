import Foundation
import AVFoundation

/// Looping ambient-sound player with crossfade between tracks.
///
/// Uses a category of `.ambient` so the audio:
///   • respects the silent-mode switch
///   • mixes with other audio (Apple Music / podcasts)
///   • does NOT continue when the app is backgrounded
///
/// Upgrade path: switch to `.playback` + `UIBackgroundModes = [audio]` in
/// Info.plist if we want continued playback during sleep.
final class AmbientPlayer {
    static let shared = AmbientPlayer()

    private var player: AVAudioPlayer?
    private(set) var current: BackgroundSound = .off
    private var sessionConfigured = false

    /// Linear volume in [0, 1]. Persisted in AppState; mirrored here.
    var volume: Float = 0.6 {
        didSet {
            player?.volume = effectiveVolume
        }
    }

    private var effectiveVolume: Float {
        guard current != .off else { return 0 }
        return max(0, min(1, volume))
    }

    private init() {}

    // MARK: - Public API

    /// Switches to a new background sound, fading the previous one out and
    /// the new one in over `fade` seconds.
    func play(_ sound: BackgroundSound, fade: TimeInterval = 0.6) {
        guard sound != current else {
            // Same sound; just update volume in case it changed.
            player?.volume = effectiveVolume
            return
        }
        configureSessionIfNeeded()

        // Fade out & release the existing player.
        if let old = player {
            old.setVolume(0, fadeDuration: fade)
            // Schedule stop after the fade completes.
            DispatchQueue.main.asyncAfter(deadline: .now() + fade + 0.05) { [weak old] in
                old?.stop()
            }
        }
        player = nil

        guard let name = sound.resourceName,
              let url = locateResource(name: name, ext: sound.resourceExtension)
        else {
            current = .off
            return
        }

        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1               // loop forever
            p.volume = 0
            p.prepareToPlay()
            p.play()
            p.setVolume(effectiveVolumeFor(sound), fadeDuration: fade)
            player = p
            current = sound
        } catch {
            #if DEBUG
            print("AmbientPlayer: failed to load \(name).mp3 — \(error)")
            #endif
            current = .off
        }
    }

    /// Stop and release immediately.
    func stop(fade: TimeInterval = 0.4) {
        guard let p = player else { current = .off; return }
        p.setVolume(0, fadeDuration: fade)
        DispatchQueue.main.asyncAfter(deadline: .now() + fade + 0.05) { [weak p] in
            p?.stop()
        }
        player = nil
        current = .off
    }

    // MARK: - Helpers

    private func effectiveVolumeFor(_ sound: BackgroundSound) -> Float {
        sound == .off ? 0 : max(0, min(1, volume))
    }

    /// Look up a bundled audio resource. Synchronized groups in modern Xcode
    /// usually flatten resources to the bundle root, but folder references
    /// preserve hierarchy — try both.
    private func locateResource(name: String, ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        for subdir in ["Audio", "Resources/Audio"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdir) {
                return url
            }
        }
        return nil
    }

    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
            sessionConfigured = true
        } catch {
            #if DEBUG
            print("AmbientPlayer: audio session setup failed — \(error)")
            #endif
        }
    }
}
