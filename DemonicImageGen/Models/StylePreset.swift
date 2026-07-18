//
//  StylePreset.swift
//  DemonicImageGen
//
//  Vordefinierte dämonische Stil-Presets, die den Prompt anreichern,
//  bevor er ans Backend gesendet wird.
//

import Foundation

enum StylePreset: String, CaseIterable, Identifiable, Codable {
    case shadowRealm = "Schattenreich"
    case infernoRed = "Höllenfeuer"
    case voidPurple = "Leere"
    case toxicGreen = "Verseucht"
    case none = "Kein Stil"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .shadowRealm: return "moon.stars.fill"
        case .infernoRed: return "flame.fill"
        case .voidPurple: return "sparkles"
        case .toxicGreen: return "leaf.fill"
        case .none: return "slash.circle"
        }
    }

    /// Wird an den Nutzer-Prompt angehängt, um den dämonischen Look zu erzwingen.
    var promptSuffix: String {
        switch self {
        case .shadowRealm:
            return ", dark fantasy demonic style, gothic horror, deep shadows, glowing purple eyes, cinematic lighting, highly detailed, occult atmosphere"
        case .infernoRed:
            return ", demonic hellfire style, molten lava, burning embers, infernal red and orange glow, cinematic, highly detailed"
        case .voidPurple:
            return ", demonic void style, cosmic horror, violet and black energy, eldritch, glowing runes, highly detailed, dramatic lighting"
        case .toxicGreen:
            return ", demonic toxic style, acid green glow, cursed swamp atmosphere, corrupted magic, highly detailed, eerie lighting"
        case .none:
            return ""
        }
    }
}
