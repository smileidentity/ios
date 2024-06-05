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

let errorMappings: [Set<String>: String] = [
    ["2201", "2301", "2401"]: "Si.Error.Message.2201.2301.2401",
    ["2205", "2405"]: "Si.Error.Message.2205.2405",
    ["2213", "2413"]: "Si.Error.Message.2213.2413",
    ["2203"]: "Si.Error.Message.2203",
    ["2204"]: "Si.Error.Message.2204",
    ["2207"]: "Si.Error.Message.2207",
    ["2208"]: "Si.Error.Message.2208",
    ["2209"]: "Si.Error.Message.2209",
    ["2210"]: "Si.Error.Message.2210",
    ["2211"]: "Si.Error.Message.2211",
    ["2212"]: "Si.Error.Message.2212",
    ["2215"]: "Si.Error.Message.2215",
    ["2216"]: "Si.Error.Message.2216",
    ["2220"]: "Si.Error.Message.2220",
    ["2221"]: "Si.Error.Message.2221",
    ["2314"]: "Si.Error.Message.2314",
    ["2414"]: "Si.Error.Message.2414"
]

func findErrorMessage(for code: String) -> String {
    for (codes, message) in errorMappings {
        if codes.contains(code) {
            return message
        }
    }
    return "Confirmation.FailureReason"
}

func toErrorMessage(error: SmileIDError) -> (String, String?) {
    switch error {
    case .api(let code, let message):
        let errorMessage = findErrorMessage(for: code)
        return (errorMessage, message)
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
