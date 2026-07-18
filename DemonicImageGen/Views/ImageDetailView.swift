//
//  ImageDetailView.swift
//  DemonicImageGen
//

import Combine
import SwiftUI
import UIKit

struct ImageDetailView: View {
    let item: GeneratedImage
    @EnvironmentObject private var historyStore: ImageHistoryStore
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                DemonicBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let uiImage = historyStore.uiImage(for: item) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: DemonicTheme.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DemonicTheme.cornerRadius)
                                        .stroke(DemonicTheme.hairline, lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("PROMPT")
                                .font(.demonicHeadline(11))
                                .foregroundStyle(DemonicTheme.textFaint)
                                .tracking(1.2)
                            Text(item.prompt)
                                .font(.demonicBody(15))
                                .foregroundStyle(DemonicTheme.textPrimary)

                            HStack(spacing: 14) {
                                Label(item.style.rawValue, systemImage: item.style.icon)
                                Label("\(item.width)×\(item.height)", systemImage: "aspectratio")
                            }
                            .font(.demonicBody(12))
                            .foregroundStyle(DemonicTheme.textSecondary)
                            .padding(.top, 4)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: DemonicTheme.cornerRadiusSmall)
                                .fill(DemonicTheme.surface)
                        )

                        HStack(spacing: 12) {
                            if let uiImage = historyStore.uiImage(for: item) {
                                GlowIconButton(systemImage: "square.and.arrow.up") {
                                    share(image: uiImage)
                                }
                                GlowIconButton(systemImage: "square.and.arrow.down") {
                                    UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                                }
                            }
                            GlowIconButton(systemImage: "trash") {
                                showDeleteConfirmation = true
                            }
                            Spacer()
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundStyle(DemonicTheme.spotifyGreen)
                }
            }
            .confirmationDialog(
                "Diese Beschwörung wirklich löschen?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    historyStore.delete(item)
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) {}
            }
        }
        .preferredColorScheme(.dark)
    }

    private func share(image: UIImage) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        root.present(activityVC, animated: true)
    }
}
