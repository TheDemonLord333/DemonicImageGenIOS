//
//  StyleChip.swift
//  DemonicImageGen
//

import SwiftUI

struct StyleChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.demonicHeadline(13))
            .foregroundStyle(isSelected ? .white : DemonicTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isSelected ? AnyShapeStyle(DemonicTheme.summonGradient) : AnyShapeStyle(DemonicTheme.surface))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : DemonicTheme.hairline, lineWidth: 1)
            )
        }
    }
}
