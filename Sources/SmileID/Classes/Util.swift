import Foundation
import SwiftUI

public func generateJobId() -> String {
    generateId("job-")
}

public func generateUserId() -> String {
    generateId("user-")
}

private func generateId(_ prefix: String) -> String {
    prefix + UUID().uuidString
}

public extension View {
    /// Cuts out the given shape from the view. This is used instead of a ZStack with a shape and a
    /// blendMode of .destinationOut because that causes issues on iOS 14 devices
    func cutout<S: Shape>(_ shape: S) -> some View {
        self.clipShape(
            StackedShape(bottom: Rectangle(), top: shape),
            style: FillStyle(eoFill: true)
        )
    }
}

private struct StackedShape<Bottom: Shape, Top: Shape>: Shape {
    var bottom: Bottom
    var top: Top

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addPath(bottom.path(in: rect))
            path.addPath(top.path(in: rect))
        }
    }
}

extension String: Error {}

enum FileType: String {
    case selfie = "si_selfie"
    case liveness = "si_liveness"
    case documentFront = "si_document_front"
    case documentBack = "si_document_back"

    var name: String {
        return rawValue
    }
}

extension String {
    func nilIfEmpty() -> String? {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}

func toErrorMessage(error: SmileIDError) -> (String, String?) {
    switch error {
    case .api(let code, let message):
        let errorMessage = "Si.Error.Message.\(code)"
        return (errorMessage, message)
    case let .request(error):
        return (error.localizedDescription, nil)
    case .httpError(_, let message):
        return ("", message)
    default:
        return ("Confirmation.FailureReason", nil)
    }
}

func getErrorSubtitle(errorMessageRes: String?, errorMessage: String?) -> String {
    if let errorMessageRes = errorMessageRes, !SmileIDResourcesHelper.localizedString(for: errorMessageRes).isEmpty {
        return SmileIDResourcesHelper.localizedString(for: errorMessageRes)
    } else if let errorMessage = errorMessage, !errorMessage.isEmpty {
        return errorMessage
    } else {
        return SmileIDResourcesHelper.localizedString(for: "Confirmation.FailureReason")
    }
}

func getRelativePath(from absoluteURL: URL?) -> URL? {
    guard let absoluteURL = absoluteURL else {
        return nil
    }

    let relativeComponents = absoluteURL.pathComponents
        .drop(while: { $0 != "SmileID" })
        .dropFirst()

    if relativeComponents.isEmpty {
        return absoluteURL
    } else {
        return URL(string: relativeComponents.joined(separator: "/"))
    }
}

struct MonotonicTime {
    private let startTime: UInt64
    
    init() {
        startTime = mach_absolute_time()
    }
    
    func elapsedTime() -> TimeInterval {
        let endTime = mach_absolute_time()
        let elapsed = endTime - startTime
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        let elapsedNano = elapsed * UInt64(timebase.numer) / UInt64(timebase.denom)
        return TimeInterval(elapsedNano) / TimeInterval(NSEC_PER_SEC)
    }
}
