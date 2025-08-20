import SwiftUI

@MainActor
public final class VerificationFlowState: ObservableObject {
  @Published public var docInfo: [String: String] = [:]
  @Published public var docFrontImage: UIImage?
  @Published public var docBackImage: UIImage?
  @Published public var selfieImage: UIImage?

  public init() {}
}

