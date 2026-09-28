//
//  CloudflareModel.swift
//  DemonicImageGen
//
//  Verfuegbare Bildmodelle fuer das Cloudflare-Workers-AI-Backend. Nicht
//  alle akzeptieren eine eigene Breite/Hoehe -- flux-1-schnell lehnt
//  width/height/seed serverseitig ab (siehe backend2/server.js).
//

import Foundation

enum CloudflareModel: String, CaseIterable, Identifiable, Codable {
    case flux
    case stableDiffusionXL = "stable-diffusion-xl"
    case lightning
    case dreamshaper

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flux: return "Flux (schnell)"
        case .stableDiffusionXL: return "Stable Diffusion XL"
        case .lightning: return "SDXL Lightning"
        case .dreamshaper: return "Dreamshaper"
        }
    }

    var icon: String {
        switch self {
        case .flux: return "bolt.fill"
        case .stableDiffusionXL, .lightning, .dreamshaper: return "aspectratio"
        }
    }

    /// Nur Modelle außerhalb der Flux-Familie akzeptieren eine eigene
    /// Breite/Höhe bei Cloudflare Workers AI.
    var supportsCustomSize: Bool {
        self != .flux
    }
}
