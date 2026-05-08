import Foundation

/// Background ambience options. Each non-`off` case maps to a bundled audio
/// resource that loops indefinitely.
enum BackgroundSound: String, Codable, CaseIterable, Identifiable {
    case off
    case rain
    case forest
    case cat

    var id: String { rawValue }

    /// Display label for Settings (UPPER + tracked per design system).
    var label: String {
        switch self {
        case .off:    return "OFF"
        case .rain:   return "RAIN"
        case .forest: return "FOREST"
        case .cat:    return "CAT"
        }
    }

    /// Short copy under the label.
    var caption: String {
        switch self {
        case .off:    return "No ambience"
        case .rain:   return "Steady rain — calming, masks engine noise"
        case .forest: return "Forest — birds, distant wind"
        case .cat:    return "Purring cat — close, low-frequency"
        }
    }

    /// Filename of the bundled resource (sans extension).
    var resourceName: String? {
        switch self {
        case .off:    return nil
        case .rain:   return "rain"
        case .forest: return "forest"
        case .cat:    return "cat"
        }
    }

    var resourceExtension: String { "mp3" }
}
