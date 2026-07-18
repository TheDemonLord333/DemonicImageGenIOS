//
//  GlowButton.swift
//  DemonicImageGen
//

import SwiftUI

struct GlowButton: View {
    let title: String
    var systemImage: String? = nil
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.demonicHeadline())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(DemonicTheme.summonGradient)
            )
            .shadow(color: DemonicTheme.demonicViolet.opacity(isDisabled ? 0 : 0.5), radius: 14, y: 6)
            .shadow(color: DemonicTheme.spotifyGreen.opacity(isDisabled ? 0 : 0.25), radius: 20, y: 0)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

struct GlowIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DemonicTheme.textPrimary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(DemonicTheme.surfaceElevated)
                        .overlay(Circle().stroke(DemonicTheme.hairline, lineWidth: 1))
                )
        }
    }
}

#Preview {
    ZStack {
        DemonicBackground()
        VStack(spacing: 20) {
            GlowButton(title: "Beschwören", systemImage: "flame.fill") {}
            GlowIconButton(systemImage: "square.and.arrow.up") {}
        }
        .padding()
    }
}
