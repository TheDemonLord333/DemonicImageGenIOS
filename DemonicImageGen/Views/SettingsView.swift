//
//  SettingsView.swift
//  DemonicImageGen
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var connectionState: ConnectionState = .idle

    enum ConnectionState: Equatable {
        case idle, checking, success, failure
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DemonicBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Einstellungen")
                                .font(.demonicTitle(24))
                                .foregroundStyle(DemonicTheme.textPrimary)
                            Text("Verbinde die App mit deinem eigenen Node-Backend.")
                                .font(.demonicBody(13))
                                .foregroundStyle(DemonicTheme.textSecondary)
                        }

                        section(title: "BACKEND-URL") {
                            GlowTextField(
                                placeholder: "https://dein-server.de",
                                text: $settings.backendURL,
                                keyboardType: .URL
                            )
                        }

                        section(title: "API-KEY (OPTIONAL)") {
                            GlowTextField(
                                placeholder: "Nur nötig, falls im Backend gesetzt",
                                text: $settings.apiKey,
                                isSecure: true
                            )
                        }

                        GlowButton(
                            title: connectionTitle,
                            systemImage: connectionIcon,
                            isDisabled: connectionState == .checking
                        ) {
                            Task { await checkConnection() }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("ÜBER")
                                .font(.demonicHeadline(12))
                                .foregroundStyle(DemonicTheme.textFaint)
                                .tracking(1.2)
                            Text("Demonic Pic Gen sendet deine Prompts an dein eigenes Backend, welches sie an die Pollinations-API weiterleitet. Es werden keine Daten an Dritte außer Pollinations übertragen.")
                                .font(.demonicBody(13))
                                .foregroundStyle(DemonicTheme.textSecondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: DemonicTheme.cornerRadiusSmall)
                                .fill(DemonicTheme.surface)
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.demonicHeadline(12))
                .foregroundStyle(DemonicTheme.textFaint)
                .tracking(1.2)
            content()
        }
    }

    private var connectionTitle: String {
        switch connectionState {
        case .idle: return "Verbindung testen"
        case .checking: return "Prüfe..."
        case .success: return "Verbindung erfolgreich"
        case .failure: return "Verbindung fehlgeschlagen"
        }
    }

    private var connectionIcon: String {
        switch connectionState {
        case .idle: return "bolt.fill"
        case .checking: return "hourglass"
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.circle.fill"
        }
    }

    private func checkConnection() async {
        connectionState = .checking
        let service = BackendService(settings: settings)
        let isHealthy = await service.checkHealth()
        connectionState = isHealthy ? .success : .failure
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
}
