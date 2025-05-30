import Foundation

public enum FailureReason: Codable {
    case mobileActiveLivenessTimeout

    private enum CodingKeys: String, CodingKey {
        case mobileActiveLivenessTimeout = "mobile_active_liveness_timed_out"
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .mobileActiveLivenessTimeout:
            try container.encode(true, forKey: .mobileActiveLivenessTimeout)
        }
    }
}
