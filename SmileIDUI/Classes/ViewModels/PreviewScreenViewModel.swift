import Combine
import SwiftUI

@MainActor
class PreviewScreenViewModel: ObservableObject {
  // MARK: - Configuration

  let capturedImage: Data?
  let scanType: ScanType
  let onContinue: () -> Void
  let onRetry: () -> Void

  // MARK: - Published State

  @Published var previewState: PreviewState = .displaying
  @Published var errorState: ErrorState?
  @Published var isImageLoading = false

  // MARK: - Private State

  private var subscribers = Set<AnyCancellable>()

  init(
    capturedImage: Data?,
    scanType: ScanType,
    onContinue: @escaping () -> Void,
    onRetry: @escaping () -> Void
  ) {
    self.capturedImage = capturedImage
    self.scanType = scanType
    self.onContinue = onContinue
    self.onRetry = onRetry
  }

  deinit {
    subscribers.removeAll()
  }

  // MARK: - Actions

  func acceptImage() {
    // Future: Implement acceptance logic
    onContinue()
  }

  func rejectImage() {
    // Future: Implement rejection logic
    onRetry()
  }

  func loadPreview() {
    // Future: Implement image loading/processing
  }
}

// MARK: - Supporting Types

enum PreviewState {
  case loading
  case displaying
  case processing
  case error
}
