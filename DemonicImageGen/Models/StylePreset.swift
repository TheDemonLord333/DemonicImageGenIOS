//
//  StylePreset.swift
//  DemonicImageGen
//
//  Vordefinierte dämonische Stil-Presets, die den Prompt anreichern,
//  bevor er ans Backend gesendet wird.
//
//  Vorschaubilder: Assets.xcassets/StylePreviews/<displayName>.imageset
//  Aktuell weiße 1:1-Platzhalter. Um echte Vorschaubilder einzusetzen,
//  einfach die PNG-Datei in genau diesem Imageset (gleicher Dateiname)
//  ersetzen – kein Code muss angepasst werden.
//

import Foundation

enum StylePreset: String, CaseIterable, Identifiable, Codable {
    case none
    case shadowRealm
    case hellfire
    case void
    case toxic
    case bloodMoon
    case necromancy
    case demonLord
    case hellMachine
    case soulReaper
    case graveyard
    case runeMagic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "Kein Stil"
        case .shadowRealm: return "Schattenreich"
        case .hellfire: return "Höllenfeuer"
        case .void: return "Leere"
        case .toxic: return "Verseucht"
        case .bloodMoon: return "Blutmond"
        case .necromancy: return "Nekromantie"
        case .demonLord: return "Dämonenfürst"
        case .hellMachine: return "Höllenmaschine"
        case .soulReaper: return "Seelenfänger"
        case .graveyard: return "Friedhof"
        case .runeMagic: return "Runenmagie"
        }
    }

    var icon: String {
        switch self {
        case .none: return "slash.circle"
        case .shadowRealm: return "moon.stars.fill"
        case .hellfire: return "flame.fill"
        case .void: return "sparkles"
        case .toxic: return "leaf.fill"
        case .bloodMoon: return "moon.fill"
        case .necromancy: return "skull.fill"
        case .demonLord: return "crown.fill"
        case .hellMachine: return "gearshape.fill"
        case .soulReaper: return "wind"
        case .graveyard: return "cross.fill"
        case .runeMagic: return "wand.and.stars"
        }
    }

    /// Name des Imagesets in Assets.xcassets/StylePreviews fuer die
    /// Vorschaukachel im Stil-Picker. Entspricht dem sichtbaren Namen.
    var previewAssetName: String { displayName }

    /// Wird an den Nutzer-Prompt angehängt, um den dämonischen Look zu erzwingen.
    var promptSuffix: String {
        switch self {
        case .none:
            return ""
        case .shadowRealm:
            return ", dark fantasy demonic style, gothic horror, deep shadows, glowing purple eyes, cinematic lighting, highly detailed, occult atmosphere"
        case .hellfire:
            return ", demonic hellfire style, molten lava, burning embers, infernal red and orange glow, cinematic, highly detailed"
        case .void:
            return ", demonic void style, cosmic horror, violet and black energy, eldritch, glowing runes, highly detailed, dramatic lighting"
        case .toxic:
            return ", demonic toxic style, acid green glow, cursed swamp atmosphere, corrupted magic, highly detailed, eerie lighting"
        case .bloodMoon:
            return ", blood moon demonic style, crimson red sky, dark ritual altar, ominous lighting, highly detailed, gothic horror atmosphere"
        case .necromancy:
            return ", necromancy demonic style, undead skeletal magic, glowing green death runes, dark graveyard mist, highly detailed, macabre atmosphere"
        case .demonLord:
            return ", demon lord royal style, ornate infernal throne, regal dark armor, glowing crown of horns, highly detailed, majestic and menacing"
        case .hellMachine:
            return ", infernal machine demonic style, biomechanical demon, industrial hellscape, glowing pipes and gears, highly detailed, dark sci-fi horror"
        case .soulReaper:
            return ", soul reaper demonic style, spectral wraith, tattered cloak, glowing soul wisps, scythe, highly detailed, haunting atmosphere"
        case .graveyard:
            return ", gothic graveyard demonic style, ancient tombstones, thick fog, crows, moonlit cemetery, highly detailed, eerie atmosphere"
        case .runeMagic:
            return ", rune magic demonic style, glowing occult runes, arcane sigils, magical energy, highly detailed, mystical dark atmosphere"
        }
    }
}
