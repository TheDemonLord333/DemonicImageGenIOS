//
//  DemonicBackground.swift
//  DemonicImageGen
//

import SwiftUI

/// Dunkler Hintergrund mit grün/violettem Glüh-Effekt, angelehnt an das App-Icon.
struct DemonicBackground: View {
    var body: some View {
        ZStack {
            DemonicTheme.voidBlack
            DemonicTheme.backgroundGlow
            DemonicTheme.backgroundGlowSecondary
        }
        .ignoresSafeArea()
    }
}

#Preview {
    DemonicBackground()
}
