//
//  ContentView.swift
//  DemonicImageGen
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var settings: AppSettings
    @StateObject private var historyStore: ImageHistoryStore
    @StateObject private var generatorViewModel: GeneratorViewModel

    init() {
        let settings = AppSettings()
        let historyStore = ImageHistoryStore()
        _settings = StateObject(wrappedValue: settings)
        _historyStore = StateObject(wrappedValue: historyStore)
        _generatorViewModel = StateObject(
            wrappedValue: GeneratorViewModel(settings: settings, historyStore: historyStore)
        )
    }

    var body: some View {
        TabView {
            GeneratorView(viewModel: generatorViewModel)
                .tabItem {
                    Label("Beschwören", systemImage: "flame.fill")
                }

            HistoryView()
                .tabItem {
                    Label("Grimoire", systemImage: "book.closed.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape.fill")
                }
        }
        .tint(DemonicTheme.spotifyGreen)
        .environmentObject(settings)
        .environmentObject(historyStore)
        .preferredColorScheme(.dark)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(DemonicTheme.abyss)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
}
