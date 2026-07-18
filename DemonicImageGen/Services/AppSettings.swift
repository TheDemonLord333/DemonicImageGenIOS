//
//  AppSettings.swift
//  DemonicImageGen
//

import Combine
import Foundation
import SwiftUI

/// Persistierte Einstellungen der App (Backend-URL, API-Key), zentral über @AppStorage.
final class AppSettings: ObservableObject {
    @AppStorage("backendURL") var backendURL: String = "https://your-server.example.com"
    @AppStorage("apiKey") var apiKey: String = ""
}
