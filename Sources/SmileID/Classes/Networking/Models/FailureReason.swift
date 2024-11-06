import Foundation

public enum FailureReason {
    case activeLivenessTimedOut

    var key: String {
        switch self {
        case .activeLivenessTimedOut: return "mobile_active_liveness_timed_out"
        }
    }
}
