import Foundation
import UIKit

enum LocalNetworkHostResolver {
    /// mDNS hostname for the host device (e.g. `rupalis-iphone.local`).
    static func bonjourHostName() -> String? {
        let raw = UIDevice.current.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }

        let folded = raw.folding(options: .diacriticInsensitive, locale: .current)
        let parts = folded.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }

        return parts.joined(separator: "-").lowercased() + ".local"
    }

    static func joinBaseURL(port: UInt16, ipAddress: String) -> String {
        if let hostName = bonjourHostName() {
            return "http://\(hostName):\(port)"
        }
        return "http://\(ipAddress):\(port)"
    }
}
