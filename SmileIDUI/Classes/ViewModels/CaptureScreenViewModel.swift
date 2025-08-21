import Combine
import SwiftUI

@MainActor
class CaptureScreenViewModel: ObservableObject {

	// MARK: - Configuration
	let scanType: ScanType
	let onContinue: () -> Void

	// MARK: - Published State
	@Published var captureState: CaptureState = .idle
	@Published var capturedImage: Data?
	@Published var errorState: ErrorState?

	// MARK: - Private State
	private var subscribers = Set<AnyCancellable>()

	init(
		scanType: ScanType,
		onContinue: @escaping () -> Void
	) {
		self.scanType = scanType
		self.onContinue = onContinue
	}

	deinit {
		subscribers.removeAll()
	}

	// MARK: - Actions

	func startCapture() {
		// Future: Implement capture logic
	}

	func retryCapture() {
		// Future: Implement retry logic
	}

	func acceptCapture() {
		// Future: Implement accept logic
		onContinue()
	}

	func rejectCapture() {
		// Future: Implement reject logic
	}
}

// MARK: - Supporting Types

enum CaptureState {
	case idle
	case capturing
	case completed
	case error
}

enum ErrorState: Error {
	case cameraUnavailable
	case captureFailure
}
