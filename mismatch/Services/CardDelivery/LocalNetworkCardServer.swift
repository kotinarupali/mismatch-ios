import Foundation
import Network

enum LocalNetworkCardServerError: Error {
    case failedToStart
    case noLocalAddress
}

@MainActor
final class LocalNetworkCardServer {
    private(set) var baseURL: String?
    private(set) var isRunning = false

    private var listener: NWListener?
    private let tokenStore: LocalCardTokenStore
    private let urlBuilder = CardURLBuilder()

    init(tokenStore: LocalCardTokenStore) {
        self.tokenStore = tokenStore
    }

    /// Starts the LAN server and returns card URLs keyed by player slot id.
    func start(session: GameSession) async throws -> [UUID: String] {
        stop()
        tokenStore.clear()

        var urls: [UUID: String] = [:]
        let faceDownCardCount = CardPickRules.faceDownCardCount(playerCount: session.players.count)

        for player in session.players where player.assignment != nil {
            let token = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            guard let assignment = player.assignment else { continue }
            tokenStore.register(LocalCardToken(
                token: token,
                playerSlotId: player.id,
                role: assignment.role,
                word: assignment.word,
                categoryHint: assignment.categoryHint,
                showRoleOnCard: session.settings.showRoleOnCard,
                faceDownCardCount: faceDownCardCount
            ))
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

                for player in session.players where player.assignment != nil {
                    if let token = tokenStore.tokenString(forPlayer: player.id) {
                        urls[player.id] = urlBuilder.cardURL(baseURL: url, token: token)
                    }
                }
                return urls
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
        tokenStore.clear()
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

    private func response(for request: String) -> String {
        let lines = request.split(separator: "\r\n", maxSplits: 1, omittingEmptySubsequences: false)
        guard let requestLine = lines.first else { return notFound() }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return notFound() }

        let path = String(parts[1])

        if path.hasPrefix("/c/") {
            let token = String(path.dropFirst(3))
            return htmlResponse(token: token)
        }

        if path.hasPrefix("/api/card/") {
            let token = String(path.dropFirst("/api/card/".count))
            return jsonResponse(token: token)
        }

        if path == "/card.css" {
            return textResponse(body: Self.loadResource(name: "card", ext: "css") ?? "", contentType: "text/css")
        }

        if path == "/card.js" {
            return textResponse(body: Self.loadResource(name: "card", ext: "js") ?? "", contentType: "application/javascript")
        }

        return notFound()
    }

    private func htmlResponse(token: String) -> String {
        guard tokenStore.token(for: token) != nil else {
            return htmlPage(body: "<h1>Invalid or expired card</h1>", status: 404)
        }
        let html = (Self.loadResource(name: "index", ext: "html") ?? "")
            .replacingOccurrences(of: "{{TOKEN}}", with: token)
        return htmlPage(body: html, status: 200)
    }

    private func jsonResponse(token: String) -> String {
        guard let card = tokenStore.token(for: token) else {
            return jsonPage(body: #"{"error":"not_found"}"#, status: 404)
        }

        var payload: [String: Any] = [
            "role": card.role.rawValue,
            "showRoleOnCard": card.showRoleOnCard,
            "faceDownCardCount": card.faceDownCardCount
        ]
        if let word = card.word { payload["word"] = word }
        if let hint = card.categoryHint { payload["categoryHint"] = hint }

        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let body = String(data: data, encoding: .utf8) else {
            return jsonPage(body: #"{"error":"server_error"}"#, status: 500)
        }
        return jsonPage(body: body, status: 200)
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
        let statusText = status == 200 ? "OK" : status == 404 ? "Not Found" : "Error"
        return """
        HTTP/1.1 \(status) \(statusText)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
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
