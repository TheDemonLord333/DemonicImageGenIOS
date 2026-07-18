//
//  GenerationSize.swift
//  DemonicImageGen
//

import Foundation

enum GenerationSize: String, CaseIterable, Identifiable {
    case square = "1:1"
    case portrait = "3:4"
    case landscape = "16:9"

    var id: String { rawValue }

    var dimensions: (width: Int, height: Int) {
        switch self {
        case .square: return (1024, 1024)
        case .portrait: return (896, 1152)
        case .landscape: return (1280, 720)
        }
    }
}
