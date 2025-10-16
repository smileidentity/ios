import Foundation

/// A flow for scanning something. This manages the callbacks and lifecycle of the flow.
protocol ScanFlow {
  associatedtype Parameters
  associatedtype DataType

  /**
   * Start the image processing flow for scanning a document or face.
   *
   * @param imageStream: The flow of images to process
   * @param onError: A handler to report errors to
   */
  func startFlow(
    imageStream: AsyncStream<DataType>,
    parameters: Parameters,
    onError: @escaping (Error) -> Void
  ) /**
   * In the event that the scan cannot complete, halt the flow to halt analyzers and free up CPU
   * and memory.
   */
    async

  func cancelFlow()
}
