import Foundation
import Security

enum CryptoRandom {
    static func randomBytes(count: Int) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        guard status == errSecSuccess else {
            throw CryptoRandomError.failed(status: status)
        }
        return bytes
    }

    static func shuffled<T>(_ elements: [T]) throws -> [T] {
        var result = elements
        for index in stride(from: result.count - 1, through: 1, by: -1) {
            let randomBytes = try randomBytes(count: MemoryLayout<UInt32>.size)
            let value = randomBytes.withUnsafeBytes { $0.load(as: UInt32.self) }
            let swapIndex = Int(value % UInt32(index + 1))
            result.swapAt(index, swapIndex)
        }
        return result
    }
}

enum CryptoRandomError: Error {
    case failed(status: OSStatus)
}
