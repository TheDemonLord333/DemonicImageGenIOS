//
//  GlowTextEditor.swift
//  DemonicImageGen
//

import SwiftUI
import UIKit

struct GlowTextEditor: View {
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.demonicBody())
                    .foregroundStyle(DemonicTheme.textFaint)
                    .padding(.top, 12)
                    .padding(.leading, 16)
            }
            TextEditor(text: $text)
                .focused($isFocused)
                .font(.demonicBody(16))
                .foregroundStyle(DemonicTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(10)
        }
        .frame(minHeight: 110)
        .background(
            RoundedRectangle(cornerRadius: DemonicTheme.cornerRadiusSmall)
                .fill(DemonicTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DemonicTheme.cornerRadiusSmall)
                .stroke(
                    isFocused ? AnyShapeStyle(DemonicTheme.summonGradient) : AnyShapeStyle(DemonicTheme.hairline),
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .shadow(color: isFocused ? DemonicTheme.demonicViolet.opacity(0.35) : .clear, radius: 12)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct GlowTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        Group {
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(DemonicTheme.textFaint))
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(DemonicTheme.textFaint))
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .font(.demonicBody(16))
        .foregroundStyle(DemonicTheme.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: DemonicTheme.cornerRadiusSmall)
                .fill(DemonicTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DemonicTheme.cornerRadiusSmall)
                .stroke(DemonicTheme.hairline, lineWidth: 1)
        )
    }
}
