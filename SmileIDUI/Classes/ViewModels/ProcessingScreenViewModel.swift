import Combine
import SwiftUI

@MainActor
class ProcessingScreenViewModel: ObservableObject {
  // MARK: - Configuration

  let onContinue: () -> Void
  let onCancel: () -> Void

  // MARK: - Published State

  @Published var processingState: ProcessingState = .idle
  @Published var progress: Double = 0.0
  @Published var statusMessage: String = ""
  @Published var errorState: ErrorState?
  @Published var canCancel = true

  // MARK: - Private State

  private var subscribers = Set<AnyCancellable>()
  private var processingTask: Task<Void, Never>?

  init(
    onContinue: @escaping () -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.onContinue = onContinue
    self.onCancel = onCancel
  }

  deinit {
    processingTask?.cancel()
    subscribers.removeAll()
  }

  // MARK: - Actions

  func startProcessing() {
    // Future: Implement processing logic
    processingState = .inProgress
  }

  func cancelProcessing() {
    processingTask?.cancel()
    processingState = .cancelled
    onCancel()
  }

  func continueAfterSuccess() {
    onContinue()
  }

  func retryProcessing() {
    // Future: Implement retry logic
    processingState = .idle
    startProcessing()
  }
}

// MARK: - Supporting Types

enum ProcessingState {
  case idle
  case inProgress
  case completed
  case failed
  case cancelled
}
