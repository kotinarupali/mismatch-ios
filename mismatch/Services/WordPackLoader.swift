import Foundation

enum WordPackLoaderError: Error {
    case fileNotFound
    case decodingFailed
    case emptyCatalog
}

struct WordPackLoader: Sendable {
    private static let catalogResourceName = "catalog"

    func loadCatalog() throws -> WordPackCatalog {
        guard let url = bundleURL(resourceName: Self.catalogResourceName) else {
            throw WordPackLoaderError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let catalog = try JSONDecoder().decode(WordPackCatalog.self, from: data)
        guard !catalog.packs.isEmpty else {
            throw WordPackLoaderError.emptyCatalog
        }
        return catalog
    }

    func loadBuiltIn(packId: String) throws -> WordPack {
        let catalog = try loadCatalog()
        let resourceName = catalog.packs.first(where: { $0.id == packId })?.resourceName ?? packId

        guard let url = bundleURL(resourceName: resourceName) else {
            throw WordPackLoaderError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(WordPack.self, from: data)
    }

    func summaries(selectedPackIds: Set<String>, statsProvider: (String, Int) -> WordPairStats) throws -> [WordPackSummary] {
        try loadCatalog().packs.map { entry in
            let pack = try loadBuiltIn(packId: entry.id)
            return WordPackSummary(
                id: entry.id,
                displayName: entry.displayName,
                stats: statsProvider(entry.id, pack.pairs.count),
                isSelected: selectedPackIds.contains(entry.id)
            )
        }
    }

    private func bundleURL(resourceName: String) -> URL? {
        Bundle.main.url(forResource: resourceName, withExtension: "json", subdirectory: "Resources/WordPacks")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "json")
    }
}
