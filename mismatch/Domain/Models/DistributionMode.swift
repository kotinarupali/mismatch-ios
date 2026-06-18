import Foundation

enum DistributionMode: String, Codable, CaseIterable, Sendable {
    case passThePhone
    case localQR

    var displayName: String {
        switch self {
        case .passThePhone: "Pass the Phone"
        case .localQR: "QR Cards"
        }
    }
}
