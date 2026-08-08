//
//  GeneratorView.swift
//  DemonicImageGen
//

import Combine
import SwiftUI
import UIKit

struct GeneratorView: View {
    @ObservedObject var viewModel: GeneratorViewModel
    @FocusState private var isPromptFocused: Bool
    @State private var showSaveConfirmation = false
    @State private var isStylePickerPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                DemonicBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        promptSection

                        styleSection

                        sizeSection

                        GlowButton(
                            title: viewModel.isGenerating ? "Beschwöre..." : "Beschwören",
                            systemImage: "flame.fill",
                            isDisabled: !viewModel.canGenerate
                        ) {
                            isPromptFocused = false
                            showSaveConfirmation = false
                            Task { await viewModel.generate() }
                        }

                        if let errorMessage = viewModel.errorMessage {
                            errorBanner(errorMessage)
                        }

                        resultSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Demonic Pic Gen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $isStylePickerPresented) {
            StylePickerView(selectedStyle: $viewModel.selectedStyle)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Beschwöre dein Bild")
                    .font(.demonicTitle(24))
                    .foregroundStyle(DemonicTheme.textPrimary)
                Text("Beschreibe, was aus dem Schattenreich erscheinen soll.")
                    .font(.demonicBody(13))
                    .foregroundStyle(DemonicTheme.textSecondary)
            }
            Spacer()
        }
    }

    private var promptSection: some View {
        GlowTextEditor(
            placeholder: "z.B. ein gehörnter Dämonenfürst auf einem Thron aus Knochen...",
            text: $viewModel.prompt,
            isFocused: $isPromptFocused
        )
    }

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("STIL")
                .font(.demonicHeadline(12))
                .foregroundStyle(DemonicTheme.textFaint)
                .tracking(1.2)

            Button {
                isPromptFocused = false
                isStylePickerPresented = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.selectedStyle.icon)
                        .foregroundStyle(DemonicTheme.summonGradient)
                    Text(viewModel.selectedStyle.displayName)
                        .font(.demonicHeadline(15))
                        .foregroundStyle(DemonicTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DemonicTheme.textFaint)
                }
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
            .buttonStyle(.plain)
        }
    }

    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FORMAT")
                .font(.demonicHeadline(12))
                .foregroundStyle(DemonicTheme.textFaint)
                .tracking(1.2)

            Menu {
                ForEach(GenerationSize.allCases) { size in
                    Button {
                        viewModel.selectedSize = size
                    } label: {
                        Label(size.rawValue, systemImage: size.icon)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.selectedSize.icon)
                    Text(viewModel.selectedSize.rawValue)
                        .font(.demonicHeadline(14))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(DemonicTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(DemonicTheme.surface)
                )
                .overlay(
                    Capsule().stroke(DemonicTheme.hairline, lineWidth: 1)
                )
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DemonicTheme.hellfireRed)
            Text(message)
                .font(.demonicBody(13))
                .foregroundStyle(DemonicTheme.textPrimary)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DemonicTheme.cornerRadiusSmall)
                .fill(DemonicTheme.hellfireRed.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DemonicTheme.cornerRadiusSmall)
                .stroke(DemonicTheme.hellfireRed.opacity(0.4), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var resultSection: some View {
        if viewModel.isGenerating {
            VStack {
                Spacer(minLength: 40)
                SummoningCircleView()
                Text("Der Ritus wirkt...")
                    .font(.demonicBody(13))
                    .foregroundStyle(DemonicTheme.textSecondary)
                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
        } else if let image = viewModel.resultImage {
            VStack(spacing: 14) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: DemonicTheme.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DemonicTheme.cornerRadius)
                            .stroke(DemonicTheme.hairline, lineWidth: 1)
                    )
                    .shadow(color: DemonicTheme.demonicViolet.opacity(0.3), radius: 20, y: 8)

                HStack(spacing: 12) {
                    GlowIconButton(systemImage: "square.and.arrow.up") {
                        share(image: image)
                    }
                    GlowIconButton(systemImage: "square.and.arrow.down") {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        withAnimation { showSaveConfirmation = true }
                    }
                    Spacer()
                }

                if showSaveConfirmation {
                    Text("In Fotomediathek gespeichert.")
                        .font(.demonicBody(12))
                        .foregroundStyle(DemonicTheme.spotifyGreen)
                        .transition(.opacity)
                }
            }
        }
    }

    private func share(image: UIImage) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        root.present(activityVC, animated: true)
    }
}

#Preview {
    GeneratorView(viewModel: GeneratorViewModel(settings: AppSettings(), historyStore: ImageHistoryStore()))
}
