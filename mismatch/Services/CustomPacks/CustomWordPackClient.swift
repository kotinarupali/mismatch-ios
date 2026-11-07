import Foundation

enum CustomWordPackClientError: Error, Equatable {
    case notConfigured
    case message(String)
}

struct CustomWordPackClient: Sendable {
    var session: URLSession = .shared

    func list(hostToken: String, accessToken: String?) async throws -> [CustomWordPack] {
        let payload: PackListResponse = try await send(
            method: "GET",
            path: "",
            body: Optional<HostBody>.none,
            hostToken: hostToken,
            accessToken: accessToken
        )
        return payload.packs
    }

    func generate(hostToken: String, accessToken: String?, prompt: String, count: Int, requestID: String) async throws -> GenerateResult {
        let body = GenerateBody(hostToken: hostToken, prompt: prompt, count: count, requestId: requestID)
        let payload: GenerateResponse = try await send(
            method: "POST",
            path: "",
            body: body,
            hostToken: hostToken,
            accessToken: accessToken
        )
        return try payload.result
    }

    func save(hostToken: String, accessToken: String?, title: String, requestID: String) async throws -> CustomWordPack {
        let body = SaveBody(hostToken: hostToken, title: title, requestId: requestID)
        let payload: PackResponse = try await send(
            method: "POST",
            path: "/save",
            body: body,
            hostToken: hostToken,
            accessToken: accessToken
        )
        guard let pack = payload.pack else { throw CustomWordPackClientError.message(payload.message ?? "Could not save that pack.") }
        return pack
    }

    func rename(hostToken: String, accessToken: String?, packID: String, title: String) async throws -> CustomWordPack {
        let body = TitleBody(hostToken: hostToken, title: title)
        let payload: PackResponse = try await send(
            method: "PATCH",
            path: "/\(packID)",
            body: body,
            hostToken: hostToken,
            accessToken: accessToken
        )
        guard let pack = payload.pack else { throw CustomWordPackClientError.message(payload.message ?? "Could not rename that pack.") }
        return pack
    }

    func archive(hostToken: String, accessToken: String?, packID: String) async throws {
        let body = HostBody(hostToken: hostToken)
        let _: ArchiveResponse = try await send(
            method: "POST",
            path: "/\(packID)/archive",
            body: body,
            hostToken: hostToken,
            accessToken: accessToken
        )
    }

    func markPlayed(hostToken: String, accessToken: String?, pairIDs: [String]) async throws {
        let body = PlayedBody(hostToken: hostToken, pairIds: pairIDs)
        let _: PlayedResponse = try await send(
            method: "POST",
            path: "/played",
            body: body,
            hostToken: hostToken,
            accessToken: accessToken
        )
    }

    func edit(hostToken: String, accessToken: String?, packID: String, pair: CustomWordPair) async throws -> CustomWordPack {
        let body = EditBody(
            hostToken: hostToken,
            insiderWord: pair.insiderWord,
            mismatchWord: pair.mismatchWord,
            insiderCanonical: pair.insiderCanonical,
            mismatchCanonical: pair.mismatchCanonical,
            category: pair.category
        )
        let payload: PackResponse = try await send(
            method: "PATCH",
            path: "/\(packID)/pairs/\(pair.id)",
            body: body,
            hostToken: hostToken,
            accessToken: accessToken
        )
        guard let pack = payload.pack else { throw CustomWordPackClientError.message(payload.message ?? "Could not edit that pair.") }
        return pack
    }

    func remove(hostToken: String, accessToken: String?, packID: String, pairID: String) async throws -> CustomWordPack {
        let payload: PackResponse = try await send(
            method: "POST",
            path: "/\(packID)/pairs/\(pairID)/remove",
            body: HostBody(hostToken: hostToken),
            hostToken: hostToken,
            accessToken: accessToken
        )
        guard let pack = payload.pack else { throw CustomWordPackClientError.message(payload.message ?? "Could not remove that pair.") }
        return pack
    }

    func replace(hostToken: String, accessToken: String?, packID: String, pairID: String) async throws -> CustomWordPack {
        let payload: PackResponse = try await send(
            method: "POST",
            path: "/\(packID)/pairs/\(pairID)/replace",
            body: HostBody(hostToken: hostToken),
            hostToken: hostToken,
            accessToken: accessToken
        )
        guard let pack = payload.pack else { throw CustomWordPackClientError.message(payload.message ?? "Could not replace that pair.") }
        return pack
    }

    // Signed-in deletion. The access token identifies the account. https://github.com/kotinarupali/mismatch-ios/issues/45
    func deleteAccount(hostToken: String, accessToken: String) async throws {
        let _: DeleteAccountResponse = try await send(
            method: "POST",
            path: "/delete-account",
            body: Optional<HostBody>.none,
            hostToken: hostToken,
            accessToken: accessToken
        )
    }

    func link(hostToken: String, accessToken: String) async throws -> [String] {
        let payload: LinkResponse = try await send(
            method: "POST",
            path: "/link",
            body: HostBody(hostToken: hostToken),
            hostToken: hostToken,
            accessToken: accessToken
        )
        return payload.titleConflicts ?? []
    }

    func signInWithEmail(email: String, password: String) async throws -> AuthSession {
        try await authSession(
            path: "auth/v1/token",
            query: [URLQueryItem(name: "grant_type", value: "password")],
            body: EmailPasswordBody(email: email, password: password)
        )
    }

    func createAccount(email: String, password: String) async throws -> EmailAccountResult {
        let data = try await authData(
            path: "auth/v1/signup",
            query: [],
            body: EmailPasswordBody(email: email, password: password)
        )
        if let session = try? JSONDecoder().decode(AuthSession.self, from: data), !session.accessToken.isEmpty {
            return .session(session)
        }
        return .confirmEmail
    }

    func refreshSession(refreshToken: String) async throws -> AuthSession {
        try await authSession(
            path: "auth/v1/token",
            query: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: RefreshBody(refreshToken: refreshToken)
        )
    }

    private func authSession<Body: Encodable>(path: String, query: [URLQueryItem], body: Body) async throws -> AuthSession {
        let data = try await authData(path: path, query: query, body: body)
        return try JSONDecoder().decode(AuthSession.self, from: data)
    }

    private func authData<Body: Encodable>(path: String, query: [URLQueryItem], body: Body) async throws -> Data {
        guard let base = CustomPackConfig.supabaseURL, let anon = CustomPackConfig.anonKey else {
            throw CustomWordPackClientError.notConfigured
        }
        var components = URLComponents(url: base.appendingPathSegments(path), resolvingAgainstBaseURL: false)
        if !query.isEmpty {
            components?.queryItems = query
        }
        var request = URLRequest(url: components?.url ?? base)
        request.httpMethod = "POST"
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        try Self.throwIfNeeded(data: data, response: response)
        return data
    }

    private func send<Body: Encodable, Response: Decodable>(
        method: String,
        path: String,
        body: Body?,
        hostToken: String,
        accessToken: String?
    ) async throws -> Response {
        guard let root = CustomPackConfig.functionsURL, let anon = CustomPackConfig.anonKey else {
            throw CustomWordPackClientError.notConfigured
        }
        let url = path.isEmpty ? root : root.appendingPathSegments(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anon, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken ?? anon)", forHTTPHeaderField: "Authorization")
        request.setValue(hostToken, forHTTPHeaderField: "x-host-token")
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        let (data, response) = try await session.data(for: request)
        try Self.throwIfNeeded(data: data, response: response)
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private static func throwIfNeeded(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard http.statusCode >= 400 else { return }
        if let payload = try? JSONDecoder().decode(ErrorResponse.self, from: data), let message = payload.text {
            throw CustomWordPackClientError.message(message)
        }
        throw CustomWordPackClientError.message("Could not reach custom packs.")
    }
}

enum GenerateResult: Equatable, Sendable {
    case pack(CustomWordPack, samples: [CustomWordPair])
    case titleTaken(title: String, pairs: [CustomWordPair], samples: [CustomWordPair], requestID: String)
    case failed(String)
}

private struct GenerateBody: Encodable {
    let hostToken: String
    let prompt: String
    let count: Int
    let requestId: String
}

private struct SaveBody: Encodable {
    let hostToken: String
    let title: String
    let requestId: String
}

private struct HostBody: Encodable {
    let hostToken: String
}

private struct TitleBody: Encodable {
    let hostToken: String
    let title: String
}

private struct PlayedBody: Encodable {
    let hostToken: String
    let pairIds: [String]
}

private struct EditBody: Encodable {
    let hostToken: String
    let insiderWord: String
    let mismatchWord: String
    let insiderCanonical: String
    let mismatchCanonical: String
    let category: String
}

private struct EmailPasswordBody: Encodable {
    let email: String
    let password: String
}

private struct RefreshBody: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

enum EmailAccountResult: Sendable {
    case session(AuthSession)
    case confirmEmail
}

struct AuthSession: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct AuthUser: Decodable, Sendable {
    let id: String
}

private struct ErrorResponse: Decodable {
    let error: String?
    let message: String?
    let msg: String?
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case error
        case message
        case msg
        case errorDescription = "error_description"
    }

    var text: String? {
        message ?? msg ?? errorDescription
    }
}

private struct PackListResponse: Decodable {
    let packs: [CustomWordPack]
}

private struct PackResponse: Decodable {
    let pack: CustomWordPack?
    let message: String?
    let error: String?
}

private struct ArchiveResponse: Decodable {
    let archived: Bool?
    let error: String?
    let message: String?
}

private struct PlayedResponse: Decodable {
    let updated: Int?
    let error: String?
    let message: String?
}

private struct DeleteAccountResponse: Decodable {
    let deleted: Bool?
    let error: String?
    let message: String?
}

private struct LinkResponse: Decodable {
    let linked: Bool?
    let titleConflicts: [String]?
    let error: String?
    let message: String?
}

private struct DraftPair: Decodable {
    let id: String?
    let insiderWord: String
    let mismatchWord: String
    let insiderCanonical: String
    let mismatchCanonical: String
    let category: String
    let playedAt: String?
    let isRemoved: Bool?

    var pair: CustomWordPair {
        CustomWordPair(
            id: id ?? UUID().uuidString,
            insiderWord: insiderWord,
            mismatchWord: mismatchWord,
            insiderCanonical: insiderCanonical,
            mismatchCanonical: mismatchCanonical,
            category: category,
            playedAt: playedAt,
            isRemoved: isRemoved ?? false
        )
    }
}

private struct GenerateResponse: Decodable {
    let pack: CustomWordPack?
    let titleTaken: Bool?
    let title: String?
    let pairs: [DraftPair]?
    let samples: [DraftPair]?
    let requestId: String?
    let error: String?
    let message: String?

    var result: GenerateResult {
        get throws {
            let preview = (samples ?? []).map(\.pair)
            if let pack { return .pack(pack, samples: preview) }
            if titleTaken == true, let title, let pairs, let requestId {
                return .titleTaken(title: title, pairs: pairs.map(\.pair), samples: preview, requestID: requestId)
            }
            throw CustomWordPackClientError.message(message ?? "Could not make that pack.")
        }
    }
}
