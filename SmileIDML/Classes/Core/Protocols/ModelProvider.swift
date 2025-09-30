import Foundation

protocol ModelProvider {
  associatedtype InputType
  associatedtype OutputType

  /// Unique identifier for this provider
  var identifier: String { get }

  /// Model version for telemetry and A/B testing
  var version: String { get }

  /// Perform inference asynchronously
  func predict(input: InputType) async throws -> OutputType

  /// Check if model is loaded and ready
  var isReady: Bool { get }

  /// Load model resources
  func load() async throws

  /// Unload model to free memory
  func unload()
}
