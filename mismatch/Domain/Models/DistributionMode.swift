import Foundation

enum DistributionMode: String, Sendable {
    case passThePhone
    case cloudQR

    var displayName: String {
        switch self {
        case .passThePhone: "Pass the Phone"
        case .cloudQR: "QR Cards"
        }
    }

    var detail: String {
        switch self {
        case .passThePhone:
            "Best anywhere — no internet needed. Pass one device around the circle."
        case .cloudQR:
            "Each player uses their own phone over the internet — great for picnics and outdoors."
        }
    }

    var worksOffline: Bool {
        self == .passThePhone
    }

    static var lobbyOptions: [DistributionMode] {
        if CloudCardConfig.isConfigured {
            return [.passThePhone, .cloudQR]
        }
        return [.passThePhone]
    }
}

extension DistributionMode: Codable {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "cloudQR", "localQR":
            self = .cloudQR
        case "passThePhone":
            self = .passThePhone
        default:
            self = .passThePhone
        }
    }
}

extension DistributionMode: CaseIterable {
    static var allCases: [DistributionMode] {
        lobbyOptions
    }
}
