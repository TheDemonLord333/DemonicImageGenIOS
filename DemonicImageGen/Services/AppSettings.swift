//
//  AppSettings.swift
//  DemonicImageGen
//

import Combine
import Foundation
import SwiftUI

/// Persistierte Einstellungen der App. Es koennen zwei Backends hinterlegt
/// werden (eigener Node-Server, Cloudflare Workers AI); `activeProvider`
/// bestimmt, welches davon fuer die Bildgenerierung genutzt wird.
final class AppSettings: ObservableObject {
    @AppStorage("activeProvider") private var activeProviderRaw: String = BackendProvider.node.rawValue

    @AppStorage("nodeBackendURL") var nodeBackendURL: String = "https://your-server.example.com"
    @AppStorage("nodeAPIKey") var nodeAPIKey: String = ""

    @AppStorage("cloudflareBackendURL") var cloudflareBackendURL: String = "https://your-server.example.com"
    @AppStorage("cloudflareAPIKey") var cloudflareAPIKey: String = ""
    @AppStorage("cloudflareModel") private var cloudflareModelRaw: String = CloudflareModel.flux.rawValue

    var activeProvider: BackendProvider {
        get { BackendProvider(rawValue: activeProviderRaw) ?? .node }
        set { activeProviderRaw = newValue.rawValue }
    }

    var cloudflareModel: CloudflareModel {
        get { CloudflareModel(rawValue: cloudflareModelRaw) ?? .flux }
        set { cloudflareModelRaw = newValue.rawValue }
    }

    /// Modell-Kurzname, der beim Generieren ans aktive Backend gesendet wird.
    var activeModel: String {
        switch activeProvider {
        case .node: return "flux"
        case .cloudflare: return cloudflareModel.rawValue
        }
    }

    /// Ob das aktuell aktive Backend+Modell eine eigene Bildgröße akzeptiert.
    /// Pollinations (Node-Backend) tut das immer; bei Cloudflare Workers AI
    /// hängt es vom gewählten Modell ab (siehe CloudflareModel).
    var activeModelSupportsCustomSize: Bool {
        switch activeProvider {
        case .node: return true
        case .cloudflare: return cloudflareModel.supportsCustomSize
        }
    }

    /// URL/Key des aktuell aktiven Providers. BackendService kennt nur diese
    /// beiden Properties und muss nichts vom Zwei-Backend-Konzept wissen.
    var backendURL: String {
        get { activeProvider == .node ? nodeBackendURL : cloudflareBackendURL }
        set {
            switch activeProvider {
            case .node: nodeBackendURL = newValue
            case .cloudflare: cloudflareBackendURL = newValue
            }
        }
    }

    var apiKey: String {
        get { activeProvider == .node ? nodeAPIKey : cloudflareAPIKey }
        set {
            switch activeProvider {
            case .node: nodeAPIKey = newValue
            case .cloudflare: cloudflareAPIKey = newValue
            }
        }
    }
}
