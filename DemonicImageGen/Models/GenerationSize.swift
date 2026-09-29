//
//  GenerationSize.swift
//  DemonicImageGen
//

import Foundation

enum GenerationSize: String, CaseIterable, Identifiable {
    case square = "1:1"
    case portrait = "3:4"
    case landscape4x3 = "4:3"
    case portraitTall = "9:16"
    case landscape = "16:9"
    case classicPortrait = "2:3"
    case classicLandscape = "3:2"

    var id: String { rawValue }

    var dimensions: (width: Int, height: Int) {
        switch self {
        case .square: return (1024, 1024)
        case .portrait: return (896, 1152)
        case .landscape4x3: return (1152, 896)
        case .portraitTall: return (768, 1344)
        case .landscape: return (1344, 768)
        case .classicPortrait: return (832, 1216)
        case .classicLandscape: return (1216, 832)
        }
    }

    var icon: String {
        switch self {
        case .square: return "square"
        case .portrait, .portraitTall, .classicPortrait: return "rectangle.portrait"
        case .landscape4x3, .landscape, .classicLandscape: return "rectangle"
        }
    }
}
