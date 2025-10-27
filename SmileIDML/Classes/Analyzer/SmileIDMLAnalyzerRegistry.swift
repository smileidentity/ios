import Foundation

class AnyAnalyzerFactory<Input, State, Output> {
  private let _newInstance: () async throws -> AnyAnalyzer<Input, State, Output>?

  init<F: AnalyzerFactory>(_ factory: F) where
    F.Input == Input,
    F.State == State,
    F.Output == Output {
    self._newInstance = {
      guard let analyzer = factory.newInstance() else {
        return nil
      }
      return AnyAnalyzer(analyzer)
    }
  }

  func newInstance() async throws -> AnyAnalyzer<Input, State, Output>? {
    try await _newInstance()
  }
}

typealias BaseAnalyzer = AnyAnalyzer<AnalyzerInput, IdentityScanState, AnalyzerOutput>
typealias BaseAnalyzerFactory = AnyAnalyzerFactory<AnalyzerInput, IdentityScanState, AnalyzerOutput>

class SmileIDMLAnalyzerRegistry {
  private let analyzerMap: [IdentityScanState.ScanType: [BaseAnalyzerFactory]]

  private init(analyzerMap: [IdentityScanState.ScanType: [BaseAnalyzerFactory]]) {
    self.analyzerMap = analyzerMap
  }

  func getAnalyzersFor(scanType: IdentityScanState.ScanType) -> [BaseAnalyzerFactory] {
    analyzerMap[scanType] ?? []
  }

  func hasAnalyzersFor(scanType: IdentityScanState.ScanType) -> Bool {
    analyzerMap[scanType]?.isEmpty == false
  }

  func createAnalyzersFor(scanType: IdentityScanState.ScanType) async throws -> [BaseAnalyzer] {
    guard let factories = analyzerMap[scanType] else {
      throw RegistryError.noAnalyzersRegistered(scanType: scanType)
    }

    var analyzers: [BaseAnalyzer] = []
    for factory in factories {
      if let analyzer = try? await factory.newInstance() {
        analyzers.append(analyzer)
      }
    }
    return analyzers
  }

  enum RegistryError: Error, LocalizedError {
    case noAnalyzersRegistered(scanType: IdentityScanState.ScanType)

    var errorDescription: String? {
      switch self {
      case .noAnalyzersRegistered(let scanType):
        return "No analyzers registered for \(scanType)"
      }
    }
  }

  class Builder {
    private var analyzerMap: [IdentityScanState.ScanType: [BaseAnalyzerFactory]] = [:]
    private var currentScanType: IdentityScanState.ScanType?

    @discardableResult
    func forScanType(_ scanType: IdentityScanState.ScanType) -> Builder {
      self.currentScanType = scanType
      return self
    }

    @discardableResult
    func add<F: AnalyzerFactory>(_ factory: F) -> Builder where
      F.Input == AnalyzerInput,
      F.State == IdentityScanState,
      F.Output == AnalyzerOutput {
      guard let scanType = currentScanType else {
        preconditionFailure(
          "Must call forScanType() before adding analyzers. " +
            "Example: forScanType(.document).add(...)"
        )
      }

      let anyFactory = AnyAnalyzerFactory(factory)
      analyzerMap[scanType, default: []].append(anyFactory)
      return self
    }

    @discardableResult
    func add<F: AnalyzerFactory>(_ factories: F...) -> Builder where
      F.Input == AnalyzerInput,
      F.State == IdentityScanState,
      F.Output == AnalyzerOutput {
      factories.forEach { add($0) }
      return self
    }

    func build() -> SmileIDMLAnalyzerRegistry {
      precondition(
        !analyzerMap.isEmpty,
        "Registry must have at least one analyzer registered"
      )

      return SmileIDMLAnalyzerRegistry(analyzerMap: analyzerMap)
    }
  }
}
