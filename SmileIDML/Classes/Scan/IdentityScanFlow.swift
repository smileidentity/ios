import Foundation
import UIKit

/// Identity's ScanFlow implementation, uses a pool of FaceDetectorAnalyzer or DocumentDetectorAnalyzer
/// to analyze an AsyncStream of CameraPreviewImages. The results are handled in IdentityAggregator.
class IdentityScanFlow: ScanFlow {
  typealias Parameters = IdentityScanState.ScanType
  typealias DataType = CameraPreviewImage<UIImage>

  private let analyzerLoopErrorListener: AnalyzerLoopErrorListener
  private let aggregateResultListener: any AggregateResultListener<IdentityAggregator.InterimResult, IdentityAggregator.FinalResult>

  private var aggregator: IdentityAggregator?

  /// If this is true, do not start the flow.
  private var canceled = false

  /// Pool of analyzers, initialized when startFlow is called.
  private var analyzerPool: AnalyzerPool<AnalyzerInput, IdentityScanState, AnalyzerOutput>?

  /// The loop to execute analyze, initialized upon analyzerPool is initialized.
  private var loop: ProcessBoundAnalyzerLoop<AnalyzerInput, IdentityScanState, AnalyzerOutput>?

  /// The Task to track loop, initialized upon loop starts.
  private var loopTask: Task<Void, Never>?

  init(
    analyzerLoopErrorListener: AnalyzerLoopErrorListener,
    aggregateResultListener: some AggregateResultListener<IdentityAggregator.InterimResult, IdentityAggregator.FinalResult>
  ) {
    self.analyzerLoopErrorListener = analyzerLoopErrorListener
    self.aggregateResultListener = aggregateResultListener
  }

  func startFlow(
    imageStream: AsyncStream<CameraPreviewImage<UIImage>>,
    parameters: IdentityScanState.ScanType,
    onError: @escaping (Error) -> Void
  ) {
    Task {
      if canceled {
        return
      }

      // Create aggregator
      aggregator = IdentityAggregator(
        identityScanType: parameters,
        aggregateResultListener: aggregateResultListener
      )

      // Create analyzer pool
      do {
        analyzerPool = try await createAnalyzerPool(for: parameters)
      } catch {
        await MainActor.run {
          onError(error)
        }
        return
      }

      guard let analyzerPool,
            let aggregator else {
        return
      }

      // Create processing loop
      loop = ProcessBoundAnalyzerLoop(
        analyzerPool: analyzerPool,
        resultHandler: aggregator,
        analyzerLoopErrorListener: analyzerLoopErrorListener
      )

      // Map image stream to AnalyzerInput
      let analyzerInputStream = mapStream(imageStream)

      // Subscribe to the stream
      loopTask = loop?.subscribeTo(analyzerInputStream)
    }
  }

  func cancelFlow() {
    canceled = true
    cleanUp()
  }

  /// Reset the flow to the initial state, ready to be started again
  func resetFlow() {
    canceled = false
    cleanUp()
  }

  private func createAnalyzerPool(for scanType: IdentityScanState.ScanType) async throws -> AnalyzerPool<AnalyzerInput, IdentityScanState, AnalyzerOutput> {
    let pool: AnalyzerPool<AnalyzerInput, IdentityScanState, AnalyzerOutput>

    switch scanType {
    case .selfie:
      let factory = FaceDetectorAnalyzer.Factory(minDetectionConfidence: 0.75)
      pool = await AnalyzerPool.of(
        analyzerFactory: factory,
        desiredAnalyzerCount: defaultAnalyzerParallelCount
      )
    case .document:
      let factory = DocumentDetectorAnalyzer.Factory(minDetectionConfidence: 0.75)
      pool = await AnalyzerPool.of(
        analyzerFactory: factory,
        desiredAnalyzerCount: defaultAnalyzerParallelCount
      )
    }

    return pool
  }

  private func mapStream(_ stream: AsyncStream<CameraPreviewImage<UIImage>>) -> AsyncStream<AnalyzerInput> {
    AsyncStream { continuation in
      Task {
        for await cameraPreviewImage in stream {
          let analyzerInput = AnalyzerInput(cameraPreviewImage: cameraPreviewImage)
          continuation.yield(analyzerInput)
        }
        continuation.finish()
      }
    }
  }

  private func cleanUp() {
    aggregator?.cancel()
    aggregator = nil

    loop?.unsubscribe()
    loop = nil

    analyzerPool?.closeAllAnalyzers()
    analyzerPool = nil

    loopTask?.cancel()
    loopTask = nil
  }
}
