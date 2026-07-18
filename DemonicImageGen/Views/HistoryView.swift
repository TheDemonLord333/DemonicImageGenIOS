//
//  HistoryView.swift
//  DemonicImageGen
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var historyStore: ImageHistoryStore
    @State private var selectedItem: GeneratedImage?

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                DemonicBackground()

                if historyStore.items.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(historyStore.items) { item in
                                thumbnail(for: item)
                                    .onTapGesture { selectedItem = item }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Grimoire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .sheet(item: $selectedItem) { item in
            ImageDetailView(item: item)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 44))
                .foregroundStyle(DemonicTheme.textFaint)
            Text("Noch keine Beschwörungen")
                .font(.demonicHeadline())
                .foregroundStyle(DemonicTheme.textPrimary)
            Text("Deine generierten Bilder erscheinen hier.")
                .font(.demonicBody(13))
                .foregroundStyle(DemonicTheme.textSecondary)
        }
    }

    private func thumbnail(for item: GeneratedImage) -> some View {
        Group {
            if let uiImage = historyStore.uiImage(for: item) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } else {
                Rectangle()
                    .fill(DemonicTheme.surface)
            }
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: DemonicTheme.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: DemonicTheme.cornerRadiusSmall)
                .stroke(DemonicTheme.hairline, lineWidth: 1)
        )
    }
}

#Preview {
    HistoryView()
        .environmentObject(ImageHistoryStore())
}
