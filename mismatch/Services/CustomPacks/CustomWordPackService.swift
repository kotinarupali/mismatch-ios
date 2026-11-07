import Foundation

@MainActor
@Observable
// Local copy and played upload: https://github.com/kotinarupali/mismatch-ios/issues/33
// Email account: https://github.com/kotinarupali/mismatch-ios/issues/36
final class CustomWordPackService {
    private let identity: HostIdentityStore
    private let store: CustomWordPackStore
    private let client: CustomWordPackClient

    private(set) var packs: [CustomWordPack] = []
    var lastError: String?

    init(
        identity: HostIdentityStore,
        store: CustomWordPackStore,
        client: CustomWordPackClient
    ) {
        self.identity = identity
        self.store = store
        self.client = client
        packs = store.load().packs
    }

    var isSignedIn: Bool { identity.isSignedIn }
    var isConfigured: Bool { CustomPackConfig.isConfigured }

    func reloadFromDisk() {
        packs = store.load().packs
    }

    func sync() async {
        guard CustomPackConfig.isConfigured else { return }
        await refreshIfNeeded()
        await uploadPendingArchives()
        let library = store.load()
        if !library.pendingPlayedPairIDs.isEmpty {
            try? await client.markPlayed(
                hostToken: identity.hostToken,
                accessToken: identity.accessToken,
                pairIDs: library.pendingPlayedPairIDs
            )
        }
        do {
            let remote = try await client.list(hostToken: identity.hostToken, accessToken: identity.accessToken)
            let hidden = Set(store.load().pendingArchivedPackIDs)
            var merged = remote.filter { !hidden.contains($0.id) }
            let pending = Set(store.load().pendingPlayedPairIDs)
            if !pending.isEmpty {
                merged = merged.map { pack in
                    var copy = pack
                    copy.pairs = pack.pairs.map { pair in
                        var updated = pair
                        if pending.contains(pair.id) && updated.playedAt == nil {
                            updated.playedAt = ISO8601DateFormatter().string(from: Date())
                        }
                        return updated
                    }
                    return copy
                }
            }
            packs = merged
            var saved = store.load()
            saved.packs = merged
            if library.pendingPlayedPairIDs.isEmpty == false {
                let stillPending = library.pendingPlayedPairIDs.filter { id in
                    !remote.contains { pack in pack.pairs.contains { $0.id == id && $0.playedAt != nil } }
                }
                saved.pendingPlayedPairIDs = stillPending
            }
            store.save(saved)
            lastError = nil
        } catch CustomWordPackClientError.message(let message) {
            lastError = message
        } catch CustomWordPackClientError.notConfigured {
            lastError = "Custom packs need a Supabase project."
        } catch {
            lastError = "Couldn't refresh custom packs."
        }
    }

    func generate(prompt: String, count: Int) async -> GenerateResult? {
        guard CustomPackConfig.isConfigured else {
            lastError = "Custom packs need a Supabase project."
            return nil
        }
        let requestID = UUID().uuidString
        await refreshIfNeeded()
        do {
            let result = try await client.generate(
                hostToken: identity.hostToken,
                accessToken: identity.accessToken,
                prompt: prompt,
                count: count,
                requestID: requestID
            )
            if case .pack(let pack, _) = result {
                upsert(pack)
            }
            lastError = nil
            return result
        } catch CustomWordPackClientError.message(let message) {
            lastError = message
            return .failed(message)
        } catch {
            lastError = "Couldn't make that pack."
            return .failed(lastError ?? "Couldn't make that pack.")
        }
    }

    func save(title: String, requestID: String) async -> Bool {
        await refreshIfNeeded()
        do {
            let pack = try await client.save(
                hostToken: identity.hostToken,
                accessToken: identity.accessToken,
                title: title,
                requestID: requestID
            )
            upsert(pack)
            lastError = nil
            return true
        } catch CustomWordPackClientError.message(let message) {
            lastError = message
            return false
        } catch {
            lastError = "Couldn't save that pack."
            return false
        }
    }

    func rename(packID: String, title: String) async -> Bool {
        let existing = packs.filter { $0.id != packID }.map(\.title)
        guard CustomWordRules.titleIsAvailable(title, existing: existing) else {
            lastError = "You already have a pack with that name."
            return false
        }
        await refreshIfNeeded()
        do {
            let pack = try await client.rename(
                hostToken: identity.hostToken,
                accessToken: identity.accessToken,
                packID: packID,
                title: title
            )
            upsert(pack)
            lastError = nil
            return true
        } catch CustomWordPackClientError.message(let message) {
            lastError = message
            return false
        } catch {
            lastError = "Couldn't rename that pack."
            return false
        }
    }

    func archive(packID: String) async {
        await refreshIfNeeded()
        packs.removeAll { $0.id == packID }
        var library = store.load()
        library.packs = packs
        if !library.pendingArchivedPackIDs.contains(packID) {
            library.pendingArchivedPackIDs.append(packID)
        }
        store.save(library)
        await uploadPendingArchives()
    }

    func edit(packID: String, pair: CustomWordPair) async -> Bool {
        guard let pack = packs.first(where: { $0.id == packID }) else { return false }
        let others = pack.visiblePairs.filter { $0.id != pair.id }.map(\.names)
        let blocked = Set(pack.visiblePairs.filter { $0.id != pair.id }.map {
            CustomWordRules.pairKey(insiderCanonical: $0.insiderCanonical, mismatchCanonical: $0.mismatchCanonical)
        })
        guard CustomWordRules.acceptable(
            insiderWord: pair.insiderWord,
            mismatchWord: pair.mismatchWord,
            insiderCanonical: pair.insiderCanonical,
            mismatchCanonical: pair.mismatchCanonical,
            category: pair.category,
            againstWords: others,
            blockedPairKeys: blocked
        ) else {
            lastError = "Those words are too close to another pair in this pack."
            return false
        }
        await refreshIfNeeded()
        do {
            let updated = try await client.edit(
                hostToken: identity.hostToken,
                accessToken: identity.accessToken,
                packID: packID,
                pair: pair
            )
            upsert(updated)
            lastError = nil
            return true
        } catch CustomWordPackClientError.message(let message) {
            lastError = message
            return false
        } catch {
            lastError = "Couldn't edit that pair."
            return false
        }
    }

    func remove(packID: String, pairID: String) async -> Bool {
        await refreshIfNeeded()
        do {
            let pack = try await client.remove(
                hostToken: identity.hostToken,
                accessToken: identity.accessToken,
                packID: packID,
                pairID: pairID
            )
            upsert(pack)
            lastError = nil
            return true
        } catch CustomWordPackClientError.message(let message) {
            lastError = message
            return false
        } catch {
            lastError = "Couldn't remove that pair."
            return false
        }
    }

    func replace(packID: String, pairID: String) async -> Bool {
        await refreshIfNeeded()
        do {
            let pack = try await client.replace(
                hostToken: identity.hostToken,
                accessToken: identity.accessToken,
                packID: packID,
                pairID: pairID
            )
            upsert(pack)
            lastError = nil
            return true
        } catch CustomWordPackClientError.message(let message) {
            lastError = message
            return false
        } catch {
            lastError = "Couldn't replace that pair."
            return false
        }
    }

    func nextUnplayedPair(selectionID: String) -> CustomWordPair? {
        let raw = CustomPackID.raw(selectionID)
        return packs.first { $0.id == raw }?.playablePairs.first
    }

    func contains(selectionID: String) -> Bool {
        packs.contains { $0.selectionID == selectionID || $0.id == CustomPackID.raw(selectionID) }
    }

    func markPlayed(pairID: String, selectionID: String) {
        let raw = CustomPackID.raw(selectionID)
        guard let index = packs.firstIndex(where: { $0.id == raw }) else { return }
        guard let pairIndex = packs[index].pairs.firstIndex(where: { $0.id == pairID }) else { return }
        packs[index].pairs[pairIndex].playedAt = ISO8601DateFormatter().string(from: Date())
        var library = store.load()
        library.packs = packs
        if !library.pendingPlayedPairIDs.contains(pairID) {
            library.pendingPlayedPairIDs.append(pairID)
        }
        store.save(library)
        let pending = library.pendingPlayedPairIDs
        Task {
            await refreshIfNeeded()
            do {
                try await client.markPlayed(
                    hostToken: identity.hostToken,
                    accessToken: identity.accessToken,
                    pairIDs: pending
                )
                var saved = store.load()
                saved.pendingPlayedPairIDs.removeAll { pending.contains($0) }
                store.save(saved)
            } catch {
                lastError = nil
            }
        }
    }

    func signIn(email: String, password: String) async -> String? {
        do {
            let session = try await client.signInWithEmail(email: email, password: password)
            return await finishSignIn(session)
        } catch CustomWordPackClientError.message(let message) {
            lastError = message
            return message
        } catch {
            lastError = "Couldn't sign in."
            return lastError
        }
    }

    func createAccount(email: String, password: String) async -> String? {
        do {
            switch try await client.createAccount(email: email, password: password) {
            case .session(let session):
                return await finishSignIn(session)
            case .confirmEmail:
                lastError = nil
                return "Check your email to confirm the account, then sign in."
            }
        } catch CustomWordPackClientError.message(let message) {
            lastError = message
            return message
        } catch {
            lastError = "Couldn't create that account."
            return lastError
        }
    }

    private func finishSignIn(_ session: AuthSession) async -> String? {
        identity.saveSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            userID: session.user.id
        )
        do {
            let conflicts = try await client.link(hostToken: identity.hostToken, accessToken: session.accessToken)
            await sync()
            if !conflicts.isEmpty {
                return "Two phones already use \(conflicts.joined(separator: ", ")). Rename one of them."
            }
            lastError = nil
            return nil
        } catch CustomWordPackClientError.message(let message) {
            lastError = message
            return message
        } catch {
            lastError = "Couldn't sign in."
            return lastError
        }
    }

    private func refreshIfNeeded() async {
        guard let token = identity.accessToken else { return }
        guard Self.accessTokenIsExpired(token) else { return }
        guard let refreshToken = identity.refreshToken else {
            signOut()
            return
        }
        do {
            let session = try await client.refreshSession(refreshToken: refreshToken)
            identity.saveSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userID: session.user.id
            )
        } catch {
            signOut()
        }
    }

    private static func accessTokenIsExpired(_ token: String) -> Bool {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return true }
        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - payload.count % 4) % 4
        payload += String(repeating: "=", count: padding)
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            return true
        }
        return Date().timeIntervalSince1970 > exp - 30
    }

    func signOut() {
        identity.clearSession()
        store.clear()
        packs = []
    }

    private func upsert(_ pack: CustomWordPack) {
        if let index = packs.firstIndex(where: { $0.id == pack.id }) {
            packs[index] = pack
        } else {
            packs.insert(pack, at: 0)
        }
        persist()
    }

    private func uploadPendingArchives() async {
        let ids = store.load().pendingArchivedPackIDs
        guard !ids.isEmpty else { return }
        var remaining = ids
        for id in ids {
            do {
                try await client.archive(
                    hostToken: identity.hostToken,
                    accessToken: identity.accessToken,
                    packID: id
                )
                remaining.removeAll { $0 == id }
                lastError = nil
            } catch CustomWordPackClientError.message(let message) {
                lastError = message
            } catch {
                lastError = "Couldn't archive that pack."
            }
        }
        var library = store.load()
        library.pendingArchivedPackIDs = remaining
        packs.removeAll { ids.contains($0.id) }
        library.packs = packs
        store.save(library)
    }

    private func persist() {
        var library = store.load()
        library.packs = packs
        store.save(library)
    }
}
