import AudioToolbox

/// Lightweight cues using built-in iOS system sounds — no audio assets to ship. IDs are
/// well-known community-documented system sounds, not an Apple-guaranteed stable API; an
/// invalid ID is a silent no-op rather than a crash, so this degrades safely.
enum SoundEffect {
    case buy
    case rebirth
    case achievement
    case milestone
    case luckySurge

    var systemSoundID: SystemSoundID {
        switch self {
        case .buy: return 1104
        case .rebirth: return 1025
        case .achievement: return 1025 // was 1016 ("horn") — swapped for the chime used on streak/milestone
        case .milestone: return 1025
        case .luckySurge: return 1013
        }
    }
}

enum SoundManager {
    static func play(_ effect: SoundEffect, enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }
}
