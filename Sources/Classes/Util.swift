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
  func cutout(_ shape: some Shape) -> some View {
    clipShape(
      StackedShape(bottom: Rectangle(), top: shape),
      style: FillStyle(eoFill: true))
  }
}

extension View {
  @inlinable func reverseMask(
    alignment: Alignment = .center,
    @ViewBuilder _ mask: () -> some View
  ) -> some View {
    self.mask(
      ZStack(alignment: alignment) {
        Rectangle()
        mask()
          .blendMode(.destinationOut)
      }
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

public enum FileType: String {
  case selfie = "si_selfie"
  case liveness = "si_liveness"
  case documentFront = "si_document_front"
  case documentBack = "si_document_back"

  var name: String {
    rawValue
  }
}

extension String {
  func nilIfEmpty() -> String? {
    trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
  }
}

func toErrorMessage(error: SmileIDError) -> (String, String?) {
  switch error {
  case .api(let code, let message):
    let errorMessage = "Si.Error.Message.\(code)"
    return (errorMessage, message)
  case .request(let error):
    return (error.localizedDescription, nil)
  case .httpError(_, let message):
    return ("", message)
  case .fileNotFound(let message):
    return (message, nil)
  case .unknown(let message):
    return (message, nil)
  default:
    return ("Confirmation.FailureReason", nil)
  }
}

func getErrorSubtitle(errorMessageRes: String?, errorMessage: String?) -> String {
  if let errorMessageRes, !SmileIDResourcesHelper.localizedString(for: errorMessageRes).isEmpty {
    return SmileIDResourcesHelper.localizedString(for: errorMessageRes)
  } else if let errorMessage, !errorMessage.isEmpty {
    return errorMessage
  } else {
    return SmileIDResourcesHelper.localizedString(for: "Confirmation.FailureReason")
  }
}

struct MonotonicTime {
  private var time: UInt64 = 0

  mutating func startTime() {
    time = mach_absolute_time()
  }

  func elapsedTime() -> TimeInterval {
    let endTime = mach_absolute_time()
    let elapsed = endTime - time
    var timebase = mach_timebase_info_data_t()
    mach_timebase_info(&timebase)
    let elapsedNano = elapsed * UInt64(timebase.numer) / UInt64(timebase.denom)
    return TimeInterval(elapsedNano) / TimeInterval(NSEC_PER_SEC)
  }
}

func mapToAPIError(_ error: Error) -> SmileIDError {
  if let requestError = error as? URLError {
    return .request(requestError)
  } else if let decodingError = error as? DecodingError {
    return .decode(decodingError)
  } else if let error = error as? SmileIDError {
    return error
  } else {
    return .unknown(error.localizedDescription)
  }
}

// todo we need to map errors properly (group api errors as one error)
func getExceptionHandler<T>(_ operation: () async throws -> T) async throws -> T {
  do {
    return try await operation()
  } catch {
    let error = mapToAPIError(error)
    // Only capture errors that are NOT .request or .api
    switch error {
    case .request, .api:
      // Do nothing (ignored)
      break
    default:
      SmileIDCrashReporting.hub?.capture(error: error)
    }

    throw error
  }
}

let policyNames = [
  "payload_signing",
  "payload_encryption",
  "rooted_device_check"
]

struct PolicyStatus {
  let name: String
  let active: Bool
}

extension Int? {
  func decodePolicyBitCode() -> [PolicyStatus] {
    self.map { bitCode in
      let binary = String(bitCode, radix: 2)
      let binaryArray = Array(binary.reversed()) // Reverse for easier indexing

      return policyNames.enumerated().map { index, name in
        let bit = index < binaryArray.count ? binaryArray[index] == "1" : false
        return PolicyStatus(name: name, active: bit) // bit is Bool, not Bool?
      }
    } ?? policyNames.map { PolicyStatus(name: $0, active: true) } // Default to true when nil
  }
}
