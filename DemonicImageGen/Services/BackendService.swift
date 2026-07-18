//
//  BackendService.swift
//  DemonicImageGen
//
//  Kommuniziert mit dem eigenen Node-Backend, welches die Anfragen an
//  Pollinations weiterleitet. Die App spricht NIE direkt mit Pollinations.
//

import Combine
import Foundation

enum BackendError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Die Backend-URL in den Einstellungen ist ungültig."
        case .invalidResponse:
            return "Der Server hat keine gültige Antwort geliefert."
        case .server(let message):
            return message
        case .decoding:
            return "Das Bild konnte nicht gelesen werden."
        }
    }
}

struct GenerateRequestBody: Encodable {
    let prompt: String
    let width: Int
    let height: Int
    let seed: Int
    let model: String
}

private struct ServerErrorBody: Decodable {
    let error: String
}

final class BackendService {
    private let settings: AppSettings
    private let session: URLSession

    init(settings: AppSettings, session: URLSession = .shared) {
        self.settings = settings
        self.session = session
    }

    func generateImage(
        prompt: String,
        width: Int,
        height: Int,
        seed: Int,
        model: String = "flux"
    ) async throws -> Data {
        let trimmedBase = settings.backendURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedBase)?.appendingPathComponent("api/generate") else {
            throw BackendError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        if !settings.apiKey.isEmpty {
            request.setValue(settings.apiKey, forHTTPHeaderField: "X-API-Key")
        }

        let body = GenerateRequestBody(prompt: prompt, width: width, height: height, seed: seed, model: model)
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 120

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let serverError = try? JSONDecoder().decode(ServerErrorBody.self, from: data) {
                throw BackendError.server(serverError.error)
            }
            throw BackendError.server("Server-Fehler (Status \(httpResponse.statusCode)).")
        }

        return data
    }

    func checkHealth() async -> Bool {
        let trimmedBase = settings.backendURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedBase)?.appendingPathComponent("api/health") else {
            return false
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return (200...299).contains(httpResponse.statusCode)
        } catch {
            return false
        }
    }
}
