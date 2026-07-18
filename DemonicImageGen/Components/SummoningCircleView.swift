//
//  SummoningCircleView.swift
//  DemonicImageGen
//
//  Animierter Beschwörungskreis als Ladeanzeige während der Bildgenerierung.
//

import SwiftUI

struct SummoningCircleView: View {
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 360
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(DemonicTheme.demonicViolet.opacity(0.5), lineWidth: 1.5)
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(outerRotation))

            Circle()
                .stroke(DemonicTheme.spotifyGreen.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4, 8]))
                .frame(width: 108, height: 108)
                .rotationEffect(.degrees(innerRotation))

            Star(points: 5)
                .stroke(DemonicTheme.summonGradient, lineWidth: 2)
                .frame(width: 96, height: 96)
                .rotationEffect(.degrees(outerRotation / 2))

            Image(systemName: "flame.fill")
                .font(.system(size: 30))
                .foregroundStyle(DemonicTheme.summonGradient)
                .scaleEffect(pulse ? 1.15 : 0.9)
                .shadow(color: DemonicTheme.spotifyGreen.opacity(0.6), radius: pulse ? 16 : 6)
        }
        .frame(width: 160, height: 160)
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                innerRotation = 0
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private struct Star: Shape {
    let points: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let step = Double.pi * 2 / Double(points) * 2

        var vertices: [CGPoint] = []
        for i in 0..<points {
            let angle = step * Double(i) - .pi / 2
            vertices.append(CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            ))
        }
        guard let first = vertices.first else { return path }
        path.move(to: first)
        for vertex in vertices.dropFirst() {
            path.addLine(to: vertex)
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        DemonicBackground()
        SummoningCircleView()
    }
}
