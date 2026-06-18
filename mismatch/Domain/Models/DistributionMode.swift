import Foundation

enum DistributionMode: String, Codable, CaseIterable, Sendable {
    case passThePhone
    case localQR
    case cloudQR

    var displayName: String {
        switch self {
        case .passThePhone: "Pass the Phone"
        case .localQR: "Local QR"
        case .cloudQR: "Cloud QR"
        }
    }

    var detail: String {
        switch self {
        case .passThePhone:
            "Best anywhere — no internet needed. Pass one device around the circle."
        case .localQR:
            "Each player uses their own phone on the same Wi‑Fi or host hotspot."
        case .cloudQR:
            "Each player uses their own phone over the internet — great for picnics and outdoors."
        }
    }

    var worksOffline: Bool {
        self == .passThePhone
    }

    static var lobbyOptions: [DistributionMode] {
        var modes: [DistributionMode] = [.passThePhone, .localQR]
        if CloudCardConfig.isConfigured {
            modes.append(.cloudQR)
        }
        return modes
    }
}
