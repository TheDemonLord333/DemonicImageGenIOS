import SwiftUI
import UIKit
import Combine

// MARK: - Battery Monitor

class BatteryMonitor: ObservableObject {
    @Published var level: Float = 0
    @Published var state: UIDevice.BatteryState = .unknown

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        level = max(UIDevice.current.batteryLevel, 0)
        state = UIDevice.current.batteryState

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(levelChanged),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stateChanged),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
    }

    @objc private func levelChanged() {
        DispatchQueue.main.async {
            self.level = max(UIDevice.current.batteryLevel, 0)
        }
    }

    @objc private func stateChanged() {
        DispatchQueue.main.async {
            self.state = UIDevice.current.batteryState
        }
    }

    deinit {
        UIDevice.current.isBatteryMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self)
    }

    var filledSegments: Int {
        switch level {
        case 0..<0.21: return 1
        case 0.21..<0.41: return 2
        case 0.41..<0.61: return 3
        case 0.61..<0.81: return 4
        default: return 5
        }
    }

    var segmentColor: Color {
        switch level {
        case 0..<0.21: return Color(hex: "#FF3B30")        // Rot
        case 0.21..<0.41: return Color(hex: "#FF9500")     // Orange
        case 0.41..<0.61: return Color(hex: "#FFD60A")     // Gelb
        case 0.61..<0.81: return Color(hex: "#30D158")     // Hellgrün
        default: return Color(hex: "#1DB954")              // Spotify-Grün
        }
    }

    var percentText: String {
        "\(Int(level * 100))%"
    }
}

// MARK: - Vertical Battery (Landscape)

struct VerticalBatteryView: View {
    @ObservedObject var monitor: BatteryMonitor
    let segmentWidth: CGFloat = 22
    let segmentHeight: CGFloat = 36
    let gap: CGFloat = 4

    var body: some View {
        VStack(spacing: 12) {
            // Battery tip
            Capsule()
                .fill(DemonicColor.textMuted.opacity(0.5))
                .frame(width: 10, height: 5)

            // 5 segments (top = segment 5, bottom = segment 1)
            VStack(spacing: gap) {
                ForEach((1...5).reversed(), id: \.self) { segment in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(segment <= monitor.filledSegments
                              ? monitor.segmentColor
                              : DemonicColor.backgroundElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(DemonicColor.textMuted.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(
                            color: segment <= monitor.filledSegments
                                ? monitor.segmentColor.opacity(0.5)
                                : .clear,
                            radius: 4
                        )
                        .frame(width: segmentWidth, height: segmentHeight)
                }
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DemonicColor.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DemonicColor.textMuted.opacity(0.25), lineWidth: 1.5)
                    )
            )

            // Percentage below battery
            Text(monitor.percentText)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(monitor.segmentColor)
                .shadow(color: monitor.segmentColor.opacity(0.6), radius: 4)
        }
    }
}

// MARK: - Horizontal Battery (Portrait)

struct HorizontalBatteryView: View {
    @ObservedObject var monitor: BatteryMonitor
    let segmentWidth: CGFloat = 36
    let segmentHeight: CGFloat = 22
    let gap: CGFloat = 4

    var body: some View {
        HStack(spacing: 12) {
            // Battery tip (left)
            Capsule()
                .fill(DemonicColor.textMuted.opacity(0.5))
                .frame(width: 5, height: 10)

            // 5 segments (left = segment 1, right = segment 5)
            HStack(spacing: gap) {
                ForEach(1...5, id: \.self) { segment in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(segment <= monitor.filledSegments
                              ? monitor.segmentColor
                              : DemonicColor.backgroundElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(DemonicColor.textMuted.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(
                            color: segment <= monitor.filledSegments
                                ? monitor.segmentColor.opacity(0.5)
                                : .clear,
                            radius: 4
                        )
                        .frame(width: segmentWidth, height: segmentHeight)
                }
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DemonicColor.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DemonicColor.textMuted.opacity(0.25), lineWidth: 1.5)
                    )
            )

            // Percentage rechts neben Batterie
            Text(monitor.percentText)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(monitor.segmentColor)
                .shadow(color: monitor.segmentColor.opacity(0.6), radius: 4)
        }
    }
}
