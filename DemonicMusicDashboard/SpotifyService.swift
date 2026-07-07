import Foundation
import Combine
import CryptoKit

// MARK: - Spotify Models

struct SpotifyTrack {
    let id: String
    let title: String
    let artist: String
    let albumArtURL: URL?
    let isPlaying: Bool
    let progressMs: Int
    let durationMs: Int
}

struct SpotifyTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

struct SpotifyCurrentlyPlayingResponse: Codable {
    let isPlaying: Bool
    let progressMs: Int?
    let item: SpotifyTrackItem?

    enum CodingKeys: String, CodingKey {
        case isPlaying = "is_playing"
        case progressMs = "progress_ms"
        case item
    }
}

struct SpotifyTrackItem: Codable {
    let id: String
    let name: String
    let durationMs: Int
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case durationMs = "duration_ms"
        case artists
        case album
    }
}

struct SpotifyArtist: Codable {
    let name: String
}

struct SpotifyAlbum: Codable {
    let images: [SpotifyImage]
}

struct SpotifyImage: Codable {
    let url: String
    let width: Int?
    let height: Int?
}

// MARK: - Spotify Auth Config

struct SpotifyConfig {
    static let redirectURI = "demonicmusic://callback"
    static let scopes = "user-read-currently-playing user-read-playback-state user-library-read user-library-modify"

    private struct Credentials: Decodable {
        let clientId: String
        let clientSecret: String
    }

    private static var credentials: Credentials = {
        guard let url = Bundle.main.url(forResource: "SpotifyClientToken", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let creds = try? JSONDecoder().decode(Credentials.self, from: data)
        else {
            fatalError("SpotifyClientToken.json fehlt oder ist ungültig.")
        }
        return creds
    }()

    static var clientID: String { credentials.clientId }
    static var clientSecret: String { credentials.clientSecret }
    static let authURL = "https://accounts.spotify.com/authorize"
    static let tokenURL = "https://accounts.spotify.com/api/token"
    static let currentlyPlayingURL = "https://api.spotify.com/v1/me/player/currently-playing"
    static let savedTracksContainsURL = "https://api.spotify.com/v1/me/tracks/contains"
    static let savedTracksURL = "https://api.spotify.com/v1/me/tracks"
}

// MARK: - Spotify Service

@MainActor
class SpotifyService: ObservableObject {
    @Published var currentTrack: SpotifyTrack?
    @Published var isAuthorized = false
    @Published var errorMessage: String?
    @Published var liveProgressMs: Int = 0
    @Published var isSaved: Bool = false

    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiryDate: Date?
    private var pollingTask: Task<Void, Never>?
    private var tickerTask: Task<Void, Never>?
    private var codeVerifier: String?

    private var progressAnchorMs: Int = 0
    private var progressAnchorDate: Date = Date()

    init() {
        loadTokens()
        if accessToken != nil {
            isAuthorized = true
            startPolling()
            startTicker()
        }
    }

    // MARK: - Auth URL

    func buildAuthURL() -> URL? {
        let verifier = generateCodeVerifier()
        self.codeVerifier = verifier
        guard let challenge = generateCodeChallenge(from: verifier) else { return nil }

        var components = URLComponents(string: SpotifyConfig.authURL)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: SpotifyConfig.clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: SpotifyConfig.redirectURI),
            URLQueryItem(name: "scope", value: SpotifyConfig.scopes),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge)
        ]
        return components?.url
    }

    func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            errorMessage = "Ungültige Callback-URL"
            return
        }
        Task { await exchangeCodeForToken(code: code) }
    }

    // MARK: - Token Exchange

    private func exchangeCodeForToken(code: String) async {
        guard let verifier = codeVerifier else { return }
        var request = URLRequest(url: URL(string: SpotifyConfig.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type=authorization_code",
            "code=\(code)",
            "redirect_uri=\(SpotifyConfig.redirectURI)",
            "client_id=\(SpotifyConfig.clientID)",
            "code_verifier=\(verifier)"
        ].joined(separator: "&")
        request.httpBody = bodyParams.data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
            self.accessToken = response.accessToken
            self.refreshToken = response.refreshToken
            self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(response.expiresIn))
            saveTokens()
            isAuthorized = true
            startPolling()
            startTicker()
        } catch {
            errorMessage = "Token-Austausch fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private func refreshAccessToken() async {
        guard let refresh = refreshToken else { return }
        var request = URLRequest(url: URL(string: SpotifyConfig.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type=refresh_token",
            "refresh_token=\(refresh)",
            "client_id=\(SpotifyConfig.clientID)"
        ].joined(separator: "&")
        request.httpBody = bodyParams.data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
            self.accessToken = response.accessToken
            self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(response.expiresIn))
            if let newRefresh = response.refreshToken {
                self.refreshToken = newRefresh
            }
            saveTokens()
        } catch {
            errorMessage = "Token-Refresh fehlgeschlagen"
        }
    }

    // MARK: - Polling

    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                await fetchCurrentTrack()
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        tickerTask?.cancel()
    }

    // MARK: - Smooth Progress Ticker

    private func startTicker() {
        tickerTask?.cancel()
        tickerTask = Task {
            while !Task.isCancelled {
                updateLiveProgress()
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
    }

    private func updateLiveProgress() {
        guard let track = currentTrack else { return }
        guard track.isPlaying else {
            liveProgressMs = progressAnchorMs
            return
        }
        let elapsedMs = Date().timeIntervalSince(progressAnchorDate) * 1000
        let newProgress = min(Double(progressAnchorMs) + elapsedMs, Double(track.durationMs))
        liveProgressMs = Int(newProgress)
    }

    private func fetchCurrentTrack() async {
        if let expiry = tokenExpiryDate, expiry <= Date() {
            await refreshAccessToken()
        }
        guard let token = accessToken else { return }

        var request = URLRequest(url: URL(string: SpotifyConfig.currentlyPlayingURL)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return }

            if httpResponse.statusCode == 204 {
                currentTrack = nil
                return
            }
            if httpResponse.statusCode == 401 {
                await refreshAccessToken()
                return
            }

            let playing = try JSONDecoder().decode(SpotifyCurrentlyPlayingResponse.self, from: data)
            guard let item = playing.item else {
                currentTrack = nil
                return
            }

            let artistNames = item.artists.map { $0.name }.joined(separator: ", ")
            let artURL = item.album.images.first.flatMap { URL(string: $0.url) }
            let previousTrackID = currentTrack?.id

            progressAnchorMs = playing.progressMs ?? 0
            progressAnchorDate = Date()
            liveProgressMs = progressAnchorMs

            currentTrack = SpotifyTrack(
                id: item.id,
                title: item.name,
                artist: artistNames,
                albumArtURL: artURL,
                isPlaying: playing.isPlaying,
                progressMs: playing.progressMs ?? 0,
                durationMs: item.durationMs
            )

            if previousTrackID != item.id {
                await checkSaved(trackID: item.id)
            }
        } catch {
            // Silently ignore decode errors (e.g. ads or local files)
        }
    }

    // MARK: - Save / Like Track

    private func checkSaved(trackID: String) async {
        guard let token = accessToken,
              let url = URL(string: "\(SpotifyConfig.savedTracksContainsURL)?ids=\(trackID)")
        else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try JSONDecoder().decode([Bool].self, from: data)
            isSaved = result.first ?? false
        } catch {
            // Ignore — keep previous state
        }
    }

    func toggleSaved() async {
        guard let track = currentTrack,
              let token = accessToken,
              let url = URL(string: "\(SpotifyConfig.savedTracksURL)?ids=\(track.id)")
        else { return }

        let wasSaved = isSaved
        isSaved.toggle()

        var request = URLRequest(url: url)
        request.httpMethod = wasSaved ? "DELETE" : "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                isSaved = wasSaved
                return
            }
        } catch {
            isSaved = wasSaved
        }
    }

    // MARK: - Persistence

    private func saveTokens() {
        UserDefaults.standard.set(accessToken, forKey: "spotify_access_token")
        UserDefaults.standard.set(refreshToken, forKey: "spotify_refresh_token")
        UserDefaults.standard.set(tokenExpiryDate, forKey: "spotify_token_expiry")
    }

    private func loadTokens() {
        accessToken = UserDefaults.standard.string(forKey: "spotify_access_token")
        refreshToken = UserDefaults.standard.string(forKey: "spotify_refresh_token")
        tokenExpiryDate = UserDefaults.standard.object(forKey: "spotify_token_expiry") as? Date
    }

    func logout() {
        accessToken = nil
        refreshToken = nil
        tokenExpiryDate = nil
        currentTrack = nil
        isAuthorized = false
        stopPolling()
        UserDefaults.standard.removeObject(forKey: "spotify_access_token")
        UserDefaults.standard.removeObject(forKey: "spotify_refresh_token")
        UserDefaults.standard.removeObject(forKey: "spotify_token_expiry")
    }

    // MARK: - PKCE Helpers

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String? {
        guard let data = verifier.data(using: .utf8) else { return nil }
        let digest = SHA256.hash(data: data)
        return Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
