//
//  StyleTileView.swift
//  DemonicImageGen
//

import SwiftUI

struct StyleTileView: View {
    let style: StylePreset
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if style == .none {
                emptyStyleBackground
            } else {
                Image(style.previewAssetName)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            }

            LinearGradient(
                colors: [Color.black.opacity(0.75), Color.black.opacity(0)],
                startPoint: .bottom,
                endPoint: .center
            )

            HStack(spacing: 6) {
                Image(systemName: style.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(style.displayName)
                    .font(.demonicHeadline(13))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(10)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: DemonicTheme.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: DemonicTheme.cornerRadiusSmall)
                .stroke(
                    isSelected ? AnyShapeStyle(DemonicTheme.summonGradient) : AnyShapeStyle(DemonicTheme.hairline),
                    lineWidth: isSelected ? 2.5 : 1
                )
        )
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white, DemonicTheme.spotifyGreen)
                    .padding(8)
                    .shadow(color: .black.opacity(0.5), radius: 4)
            }
        }
        .shadow(color: isSelected ? DemonicTheme.demonicViolet.opacity(0.4) : .clear, radius: 12)
    }

    private var emptyStyleBackground: some View {
        ZStack {
            DemonicTheme.surface
            Image(systemName: style.icon)
                .font(.system(size: 34))
                .foregroundStyle(DemonicTheme.textFaint)
        }
    }
}

#Preview {
    ZStack {
        DemonicBackground()
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            StyleTileView(style: .none, isSelected: true)
            StyleTileView(style: .shadowRealm, isSelected: false)
            StyleTileView(style: .hellfire, isSelected: false)
        }
        .padding()
    }
}
