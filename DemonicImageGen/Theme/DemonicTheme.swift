//
//  DemonicTheme.swift
//  DemonicImageGen
//
//  Zentrales Design-System: Spotify-Grün trifft Discord-Blurple in einem
//  düsteren, dämonischen Look.
//

import Combine
import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum DemonicTheme {
    // MARK: - Base surfaces
    static let voidBlack = Color(hex: "0A0A0D")
    static let abyss = Color(hex: "121216")
    static let surface = Color(hex: "1A1A20")
    static let surfaceElevated = Color(hex: "222229")
    static let hairline = Color(hex: "2E2E38")

    // MARK: - Brand accents
    static let spotifyGreen = Color(hex: "1ED760")
    static let spotifyGreenDeep = Color(hex: "12A64A")
    static let discordBlurple = Color(hex: "5865F2")
    static let demonicViolet = Color(hex: "9D4EDD")
    static let hellfireRed = Color(hex: "FF3860")

    // MARK: - Text
    static let textPrimary = Color(hex: "F5F5F7")
    static let textSecondary = Color(hex: "9A9AA6")
    static let textFaint = Color(hex: "5C5C66")

    // MARK: - Gradients
    static let infernalGradient = LinearGradient(
        colors: [spotifyGreen, discordBlurple, demonicViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let summonGradient = LinearGradient(
        colors: [spotifyGreen, demonicViolet],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let backgroundGlow = RadialGradient(
        colors: [demonicViolet.opacity(0.35), Color.clear],
        center: .topLeading,
        startRadius: 0,
        endRadius: 500
    )

    static let backgroundGlowSecondary = RadialGradient(
        colors: [spotifyGreen.opacity(0.22), Color.clear],
        center: .bottomTrailing,
        startRadius: 0,
        endRadius: 520
    )

    // MARK: - Metrics
    static let cornerRadius: CGFloat = 20
    static let cornerRadiusSmall: CGFloat = 14
}

extension Font {
    static func demonicTitle(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func demonicHeadline(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func demonicBody(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
}
