import Foundation
import SwiftData

enum SwiftDataContainer {
    static func makeProduction() throws -> ModelContainer {
        try ModelContainer(for: PlayerProfileEntity.self)
    }

    static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: PlayerProfileEntity.self, configurations: configuration)
    }
}
