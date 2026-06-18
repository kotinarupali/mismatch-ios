import Foundation

enum CardDeliveryService {
    case passThePhone
    case localNetwork
}

struct CardURLBuilder: Sendable {
    func cardURL(baseURL: String, token: String) -> String {
        let trimmed = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        return "\(trimmed)/c/\(token)"
    }
}
