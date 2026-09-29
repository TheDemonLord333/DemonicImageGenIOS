//
//  StylePickerView.swift
//  DemonicImageGen
//
//  Vollbild-Auswahl fuer Stil-Presets, als scrollbares Kachelraster mit
//  Beispielbildern (siehe Assets.xcassets/StylePreviews).
//

import SwiftUI

struct StylePickerView: View {
    @Binding var selectedStyle: StylePreset
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                DemonicBackground()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(StylePreset.allCases) { style in
                            Button {
                                selectedStyle = style
                                dismiss()
                            } label: {
                                StyleTileView(style: style, isSelected: style == selectedStyle)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Stil wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundStyle(DemonicTheme.spotifyGreen)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    StylePickerView(selectedStyle: .constant(.none))
}
