import Foundation
import Network

enum LocalNetworkCardServerError: Error {
    case failedToStart
    case noLocalAddress
    case webAssetsMissing
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

        guard WebCardResourceLoader.validateBundleResources() else {
            throw LocalNetworkCardServerError.webAssetsMissing
        }

        self.gameSessionStore = gameSessionStore
        sessionStore.configure(with: session)
        sessionStore.onClaim = { [weak gameSessionStore] playerId, cardIndex in
            gameSessionStore?.markCardOpened(playerId: playerId, cardIndex: cardIndex)
        }

        let parameters = NWParameters.tcp
        parameters.acceptLocalOnly = false
        parameters.includePeerToPeer = true

        let listener = try NWListener(using: parameters, on: .any)
        listener.service = NWListener.Service(type: "_mismatch._tcp")
        self.listener = listener

        listener.newConnectionHandler = { [weak self] connection in
            Task { @MainActor in
                self?.handle(connection: connection)
            }
        }

        listener.start(queue: .main)

        for _ in 0..<40 {
            if let port = listener.port, let ip = Self.localWiFiAddress() {
                let url = LocalNetworkHostResolver.joinBaseURL(port: port.rawValue, ipAddress: ip)
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
        receiveRequest(on: connection, buffer: Data())
    }

    private func receiveRequest(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 131_072) { [weak self] data, _, isComplete, _ in
            Task { @MainActor in
                guard let self else {
                    connection.cancel()
                    return
                }

                var nextBuffer = buffer
                if let data {
                    nextBuffer.append(data)
                }

                guard let raw = String(data: nextBuffer, encoding: .utf8) else {
                    connection.cancel()
                    return
                }

                let normalized = Self.normalizeHTTPRaw(raw)
                if Self.hasCompleteRequest(normalized) {
                    let response = self.response(for: normalized)
                    connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
                        connection.cancel()
                    })
                } else if isComplete {
                    if Self.headerBodySplit(normalized) != nil {
                        let response = self.response(for: normalized)
                        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
                            connection.cancel()
                        })
                    } else {
                        connection.cancel()
                    }
                } else {
                    self.receiveRequest(on: connection, buffer: nextBuffer)
                }
            }
        }
    }

    private func hasCompleteRequest(_ raw: String) -> Bool {
        guard let split = Self.headerBodySplit(raw) else { return false }
        let headers = split.headers
        let body = split.body

        for line in headers.split(separator: "\r\n") {
            let lower = line.lowercased()
            if lower.hasPrefix("content-length:") {
                let value = lower.replacingOccurrences(of: "content-length:", with: "").trimmingCharacters(in: .whitespaces)
                guard let expected = Int(value) else { return true }
                return body.utf8.count >= expected
            }
        }

        return true
    }

    private static func normalizeHTTPRaw(_ raw: String) -> String {
        if raw.contains("\r\n") { return raw }
        return raw.replacingOccurrences(of: "\n", with: "\r\n")
    }

    private static func headerBodySplit(_ raw: String) -> (headers: String, body: String)? {
        if let range = raw.range(of: "\r\n\r\n") {
            return (String(raw[..<range.lowerBound]), String(raw[range.upperBound...]))
        }
        return nil
    }

    private func response(for rawRequest: String) -> String {
        guard let request = HTTPRequest.parse(rawRequest) else { return notFound() }

        if request.method == "GET", request.path == "/favicon.ico" {
            return httpResponse(status: 204, contentType: "image/x-icon", body: "")
        }

        if request.method == "GET", request.path == "/card.css" {
            return textResponse(body: WebCardResourceLoader.css(), contentType: "text/css; charset=utf-8")
        }

        if request.method == "GET", request.path == "/card.js" {
            return textResponse(body: WebCardResourceLoader.js(), contentType: "application/javascript; charset=utf-8")
        }

        if request.method == "GET", request.path.hasPrefix("/join/") {
            let token = normalizeToken(String(request.path.dropFirst("/join/".count)))
            return htmlResponse(sessionToken: token)
        }

        if request.method == "GET", request.path.hasPrefix("/api/session/") {
            let token = normalizeToken(String(request.path.dropFirst("/api/session/".count)))
            return sessionJSONResponse(sessionToken: token)
        }

        if request.method == "POST", request.path.hasPrefix("/api/session/") {
            let remainder = String(request.path.dropFirst("/api/session/".count))
            let token = normalizeToken(remainder.split(separator: "/").first.map(String.init) ?? remainder)
            return claimJSONResponse(sessionToken: token, body: request.body)
        }

        return notFound()
    }

    private func normalizeToken(_ raw: String) -> String {
        raw.split(separator: "/").first.map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? raw
    }

    private func htmlResponse(sessionToken: String) -> String {
        guard sessionStore.sessionToken == sessionToken else {
            return htmlPage(body: "<h1>Invalid or expired game link</h1>", status: 404)
        }
        let html = WebCardResourceLoader.indexHTML(replacingToken: sessionToken)
        guard !html.isEmpty else {
            return htmlPage(body: "<h1>Game page unavailable</h1><p>Ask the host to restart distribution.</p>", status: 500)
        }
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
            "showRoleOnCard": snapshot.showRoleOnCard,
            "revision": snapshot.revision
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
                "faceDownCardCount": sessionStore.faceDownCardCount,
                "revision": sessionStore.revision
            ]
            if let word = assignment.word { payload["word"] = word }
            if let hint = assignment.categoryHint { payload["categoryHint"] = hint }
            if assignment.role == .ghost, let insiderWord = sessionStore.insiderWord {
                payload["insiderWord"] = insiderWord
            }
            return jsonPage(body: Self.encodeJSON(payload), status: 200)

        case .failure(.cardTaken):
            return jsonPage(body: #"{"error":"card_taken","revision":\#(sessionStore.revision)}"#, status: 409)
        case .failure(.alreadyClaimed):
            return jsonPage(body: #"{"error":"already_claimed","revision":\#(sessionStore.revision)}"#, status: 409)
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

    private func htmlPage(body: String, status: Int) -> String {
        httpResponse(status: status, contentType: "text/html; charset=utf-8", body: body)
    }

    private func jsonPage(body: String, status: Int) -> String {
        httpResponse(status: status, contentType: "application/json; charset=utf-8", body: body)
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
        case 500: "Internal Server Error"
        default: "Error"
        }
        return """
        HTTP/1.1 \(status) \(statusText)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        Cache-Control: no-store\r
        Access-Control-Allow-Origin: *\r
        \r
        \(body)
        """
    }

    private func notFound() -> String {
        htmlPage(body: "<h1>Not Found</h1>", status: 404)
    }

    private static func localWiFiAddress() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        let preferredInterfaces = ["en0", "en1", "pdp_ip0"]
        var found: [String: String] = [:]

        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            guard interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: interface.ifa_name)
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
            let address = String(cString: hostname)
            guard !address.isEmpty, address != "127.0.0.1" else { continue }
            found[name] = address
        }

        for interface in preferredInterfaces {
            if let address = found[interface] {
                return address
            }
        }

        return found.values.first
    }
}

private struct HTTPRequest {
    let method: String
    let path: String
    let body: String

    static func parse(_ raw: String) -> HTTPRequest? {
        let normalized = raw.contains("\r\n") ? raw : raw.replacingOccurrences(of: "\n", with: "\r\n")
        let parts = normalized.split(separator: "\r\n\r\n", maxSplits: 1, omittingEmptySubsequences: false)
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
