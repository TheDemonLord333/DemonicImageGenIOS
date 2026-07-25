//
//  BackendProvider.swift
//  DemonicImageGen
//

import Foundation

enum BackendProvider: String, CaseIterable, Identifiable, Codable {
    case node
    case cloudflare

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .node: return "Eigener Server"
        case .cloudflare: return "Cloudflare Workers AI"
        }
    }

    var icon: String {
        switch self {
        case .node: return "server.rack"
        case .cloudflare: return "cloud.fill"
        }
    }
}
