import SwiftUI

// MARK: - Demonic Color Palette (Spotify-Green × Discord-Dark)

enum DemonicColor {
    // Discord-inspired backgrounds
    static let backgroundDeep    = Color(hex: "#0D0D12")   // near-black abyss
    static let backgroundSurface = Color(hex: "#1A1A2E")   // dark navy-void
    static let backgroundCard    = Color(hex: "#16213E")   // card surface
    static let backgroundElevated = Color(hex: "#1E1E2E")  // slightly elevated

    // Spotify green corrupted with demonic purple
    static let spotifyGreen      = Color(hex: "#1DB954")   // Spotify signature
    static let demonGreen        = Color(hex: "#00FF7F")   // glowing toxic green
    static let demonPurple       = Color(hex: "#7B2FBE")   // demonic purple
    static let demonCrimson      = Color(hex: "#8B0000")   // blood crimson
    static let demonMagenta      = Color(hex: "#FF2D78")   // hot magenta

    // Discord text colors
    static let textPrimary       = Color(hex: "#FFFFFF")
    static let textSecondary     = Color(hex: "#B9BBBE")
    static let textMuted         = Color(hex: "#72767D")

    // Glow accents
    static let glowGreen         = Color(hex: "#1DB954").opacity(0.6)
    static let glowPurple        = Color(hex: "#7B2FBE").opacity(0.5)
    static let glowCrimson       = Color(hex: "#FF2D78").opacity(0.4)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Demonic Gradient

enum DemonicGradient {
    static let backgroundGradient = LinearGradient(
        colors: [DemonicColor.backgroundDeep, DemonicColor.backgroundSurface, Color(hex: "#0F0F1A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [DemonicColor.backgroundCard, DemonicColor.backgroundElevated],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let titleGradient = LinearGradient(
        colors: [DemonicColor.demonGreen, DemonicColor.spotifyGreen, DemonicColor.demonPurple],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let glowRing = AngularGradient(
        colors: [
            DemonicColor.spotifyGreen,
            DemonicColor.demonPurple,
            DemonicColor.demonCrimson,
            DemonicColor.demonMagenta,
            DemonicColor.spotifyGreen
        ],
        center: .center
    )
}

// MARK: - Demonic ViewModifiers

struct DemonicCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(DemonicGradient.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(DemonicColor.demonPurple.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: DemonicColor.glowPurple, radius: 20, x: 0, y: 0)
                    .shadow(color: DemonicColor.glowGreen.opacity(0.2), radius: 40, x: 0, y: 0)
            )
    }
}

struct PulsingGlowModifier: ViewModifier {
    @State private var glowing = false
    let color: Color

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(glowing ? 0.8 : 0.3), radius: glowing ? 20 : 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
    }
}

extension View {
    func demonicCard() -> some View {
        modifier(DemonicCardModifier())
    }

    func pulsingGlow(color: Color = DemonicColor.spotifyGreen) -> some View {
        modifier(PulsingGlowModifier(color: color))
    }
}
