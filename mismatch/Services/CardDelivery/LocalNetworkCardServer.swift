import Foundation
import Network

enum LocalNetworkCardServerError: Error {
    case failedToStart
    case noLocalAddress
}

struct SharedCardSessionStartResult: Sendable {
    let joinURL: String
    let sessionToken: String
}

@MainActor
final class LocalNetworkCardServer {
    private(set) var baseURL: String?
    private(set) var isRunning = false

    private var listener: NWListener?
    private let sessionStore: LocalCardSessionStore
    private let urlBuilder = CardURLBuilder()
    private weak var gameSessionStore: GameSessionStore?

    init(sessionStore: LocalCardSessionStore) {
        self.sessionStore = sessionStore
    }

    /// Starts the LAN server with one shared join URL for all players.
    func start(session: GameSession, gameSessionStore: GameSessionStore) async throws -> SharedCardSessionStartResult {
        stop()
        self.gameSessionStore = gameSessionStore
        sessionStore.configure(with: session)
        sessionStore.onClaim = { [weak gameSessionStore] playerId, cardIndex in
            gameSessionStore?.markCardOpened(playerId: playerId, cardIndex: cardIndex)
        }

        let listener = try NWListener(using: .tcp, on: .any)
        self.listener = listener

        listener.newConnectionHandler = { [weak self] connection in
            Task { @MainActor in
                self?.handle(connection: connection)
            }
        }

        listener.start(queue: .main)

        for _ in 0..<40 {
            if let port = listener.port, let ip = Self.localWiFiAddress() {
                let url = "http://\(ip):\(port.rawValue)"
                baseURL = url
                isRunning = true

                guard let token = sessionStore.sessionToken else {
                    stop()
                    throw LocalNetworkCardServerError.failedToStart
                }

                return SharedCardSessionStartResult(
                    joinURL: urlBuilder.sessionJoinURL(baseURL: url, sessionToken: token),
                    sessionToken: token
                )
            }
            try await Task.sleep(for: .milliseconds(50))
        }

        stop()
        throw LocalNetworkCardServerError.failedToStart
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
        baseURL = nil
        gameSessionStore = nil
        sessionStore.clear()
    }

    private func handle(connection: NWConnection) {
        connection.start(queue: .main)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            Task { @MainActor in
                guard let self, let data, let request = String(data: data, encoding: .utf8) else {
                    connection.cancel()
                    return
                }
                let response = self.response(for: request)
                connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
                    connection.cancel()
                })
            }
        }
    }

    private func response(for rawRequest: String) -> String {
        guard let request = HTTPRequest.parse(rawRequest) else { return notFound() }

        if request.method == "GET", request.path == "/card.css" {
            return textResponse(body: Self.loadResource(name: "card", ext: "css") ?? "", contentType: "text/css")
        }

        if request.method == "GET", request.path == "/card.js" {
            return textResponse(body: Self.loadResource(name: "card", ext: "js") ?? "", contentType: "application/javascript")
        }

        if request.method == "GET", request.path.hasPrefix("/join/") {
            let token = String(request.path.dropFirst("/join/".count))
            return htmlResponse(sessionToken: token)
        }

        if request.method == "GET", request.path.hasPrefix("/api/session/") {
            let token = String(request.path.dropFirst("/api/session/".count))
            return sessionJSONResponse(sessionToken: token)
        }

        if request.method == "POST", request.path.hasPrefix("/api/session/") {
            let token = String(request.path.dropFirst("/api/session/".count).split(separator: "/").first ?? "")
            return claimJSONResponse(sessionToken: token, body: request.body)
        }

        return notFound()
    }

    private func htmlResponse(sessionToken: String) -> String {
        guard sessionStore.sessionToken == sessionToken else {
            return htmlPage(body: "<h1>Invalid or expired game link</h1>", status: 404)
        }
        let html = (Self.loadResource(name: "index", ext: "html") ?? "")
            .replacingOccurrences(of: "{{TOKEN}}", with: sessionToken)
        return htmlPage(body: html, status: 200)
    }

    private func sessionJSONResponse(sessionToken: String) -> String {
        guard sessionStore.sessionToken == sessionToken, let snapshot = sessionStore.snapshot() else {
            return jsonPage(body: #"{"error":"not_found"}"#, status: 404)
        }

        let players = snapshot.players.map { player in
            [
                "id": player.id.uuidString,
                "displayName": player.displayName,
                "hasOpenedCard": player.hasOpenedCard
            ] as [String: Any]
        }

        let claimed = snapshot.claimedCards.map { card in
            [
                "cardIndex": card.cardIndex,
                "playerName": card.playerName
            ] as [String: Any]
        }

        let payload: [String: Any] = [
            "players": players,
            "claimedCards": claimed,
            "faceDownCardCount": snapshot.faceDownCardCount,
            "showRoleOnCard": snapshot.showRoleOnCard
        ]

        return jsonPage(body: Self.encodeJSON(payload), status: 200)
    }

    private func claimJSONResponse(sessionToken: String, body: String) -> String {
        guard sessionStore.sessionToken == sessionToken else {
            return jsonPage(body: #"{"error":"not_found"}"#, status: 404)
        }

        guard let data = body.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let playerIdString = object["playerId"] as? String,
              let playerId = UUID(uuidString: playerIdString),
              let cardIndex = object["cardIndex"] as? Int else {
            return jsonPage(body: #"{"error":"invalid_request"}"#, status: 400)
        }

        switch sessionStore.claimCard(playerId: playerId, cardIndex: cardIndex) {
        case .success(let assignment):
            var payload: [String: Any] = [
                "role": assignment.role.rawValue,
                "showRoleOnCard": sessionStore.showRoleOnCard,
                "faceDownCardCount": sessionStore.faceDownCardCount
            ]
            if let word = assignment.word { payload["word"] = word }
            if let hint = assignment.categoryHint { payload["categoryHint"] = hint }
            if assignment.role == .ghost, let insiderWord = sessionStore.insiderWord {
                payload["insiderWord"] = insiderWord
            }
            return jsonPage(body: Self.encodeJSON(payload), status: 200)

        case .failure(.cardTaken):
            return jsonPage(body: #"{"error":"card_taken"}"#, status: 409)
        case .failure(.alreadyClaimed):
            return jsonPage(body: #"{"error":"already_claimed"}"#, status: 409)
        case .failure(.hostMustUseApp):
            return jsonPage(body: #"{"error":"host_must_use_app"}"#, status: 403)
        case .failure(.unknownPlayer):
            return jsonPage(body: #"{"error":"unknown_player"}"#, status: 404)
        case .failure(.unknownSession):
            return jsonPage(body: #"{"error":"not_found"}"#, status: 404)
        }
    }

    private static func encodeJSON(_ payload: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let body = String(data: data, encoding: .utf8) else {
            return #"{"error":"server_error"}"#
        }
        return body
    }

    private static func loadResource(name: String, ext: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/WebCard")
            ?? Bundle.main.url(forResource: name, withExtension: ext) else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private func htmlPage(body: String, status: Int) -> String {
        httpResponse(status: status, contentType: "text/html; charset=utf-8", body: body)
    }

    private func jsonPage(body: String, status: Int) -> String {
        httpResponse(status: status, contentType: "application/json", body: body)
    }

    private func textResponse(body: String, contentType: String) -> String {
        httpResponse(status: 200, contentType: contentType, body: body)
    }

    private func httpResponse(status: Int, contentType: String, body: String) -> String {
        let statusText = switch status {
        case 200: "OK"
        case 400: "Bad Request"
        case 403: "Forbidden"
        case 404: "Not Found"
        case 409: "Conflict"
        default: "Error"
        }
        return """
        HTTP/1.1 \(status) \(statusText)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        Cache-Control: no-store\r
        \r
        \(body)
        """
    }

    private func notFound() -> String {
        htmlPage(body: "<h1>Not Found</h1>", status: 404)
    }

    private static func localWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            guard interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: interface.ifa_name)
            guard name == "en0" else { continue }
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(
                interface.ifa_addr,
                socklen_t(interface.ifa_addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            address = String(cString: hostname)
        }
        return address
    }
}

private struct HTTPRequest {
    let method: String
    let path: String
    let body: String

    static func parse(_ raw: String) -> HTTPRequest? {
        let parts = raw.split(separator: "\r\n\r\n", maxSplits: 1, omittingEmptySubsequences: false)
        let headerBlock = String(parts.first ?? "")
        let body = parts.count > 1 ? String(parts[1]) : ""

        guard let requestLine = headerBlock.split(separator: "\r\n").first else { return nil }
        let tokens = requestLine.split(separator: " ")
        guard tokens.count >= 2 else { return nil }

        let method = String(tokens[0])
        let rawPath = String(tokens[1])
        let path = rawPath.split(separator: "?", maxSplits: 1).first.map(String.init) ?? rawPath

        return HTTPRequest(method: method, path: path, body: body)
    }
}
