import Foundation

enum WordPackLoaderError: Error {
    case fileNotFound
    case decodingFailed
}

struct WordPackLoader: Sendable {
    func loadBuiltIn(packId: String = "general") throws -> WordPack {
        guard let url = Bundle.main.url(forResource: packId, withExtension: "json", subdirectory: "Resources/WordPacks")
            ?? Bundle.main.url(forResource: packId, withExtension: "json") else {
            throw WordPackLoaderError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(WordPack.self, from: data)
    }
}
