import SwiftUI

@main
struct DemonicMusicDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handled inside ContentView via SpotifyService
                    _ = url
                }
        }
    }
}
