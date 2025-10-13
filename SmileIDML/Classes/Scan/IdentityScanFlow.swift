import Foundation
import UIKit

/**
 * Identity's [ScanFlow] implementation, uses a pool of FaceDetectorAnalyzer  or DocumentDetectorAnalyzer to analyze
 * a [Flow] of [CameraPreviewImage]s. The results are handled in [IdentityAggregator].
 */
class IdentityScanFlow: ScanFlow {
  typealias Parameters = IdentityScanState.ScanType
  typealias DataType = CameraPreviewImage<UIImage>

  private let analyzerLoopErrorListener: AnalyzerLoopErrorListener

  init(analyzerLoopErrorListener: AnalyzerLoopErrorListener) {
    self.analyzerLoopErrorListener = analyzerLoopErrorListener
  }

  func startFlow(
    imageStream _: AsyncStream<CameraPreviewImage<UIImage>>,
    parameters _: IdentityScanState.ScanType,
    onError _: @escaping (Error) -> Void
  ) {
    // Implementation here
  }

  func cancelFlow() {
    // Implementation here
  }
}
