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
        let systemError = ["2201", "2301", "2401"]
        let notAuthorized = ["2205", "2405"]
        let missingParameters = ["2213", "2413"]
        
        if systemError.contains(code) {
            return ("Si.Error.Message.2201.2301.2401", message)
        } else if notAuthorized.contains(code) {
            return ("Si.Error.Message.2205.2405", message)
        } else if missingParameters.contains(code) {
            return ("Si.Error.Message.2213.2413", message)
        }
        
        switch code {
        case "2203":
            return ("Si.Error.Message.2203", message)
        case "2204":
            return ("Si.Error.Message.2204", message)
        case "2207":
            return ("Si.Error.Message.2207", message)
        case "2208":
            return ("Si.Error.Message.2208", message)
        case "2209":
            return ("Si.Error.Message.2209", message)
        case "2210":
            return ("Si.Error.Message.2210", message)
        case "2211":
            return ("Si.Error.Message.2211", message)
        case "2212":
            return ("Si.Error.Message.2212", message)
        case "2215":
            return ("Si.Error.Message.2215", message)
        case "2216":
            return ("Si.Error.Message.2216", message)
        case "2220":
            return ("Si.Error.Message.2220", message)
        case "2221":
            return ("Si.Error.Message.2221", message)
        case "2314":
            return ("Si.Error.Message.2314", message)
        case "2414":
            return ("Si.Error.Message.2414", message)
        default:
            return ("Confirmation.FailureReason", nil)
        }
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
