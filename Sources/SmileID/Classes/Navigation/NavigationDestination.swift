import UIKit

indirect enum NavigationDestination: ReflectiveEquatable {
    case selfieInstructionScreen(
        selfieCaptureViewModel: SelfieCaptureViewModel,
        delegate: SmartSelfieResultDelegate?
    )
    case selfieCaptureScreen(
        selfieCaptureViewModel: SelfieCaptureViewModel,
        delegate: SmartSelfieResultDelegate?
    )
    case documentFrontCaptureInstructionScreen(
        documentCaptureViewModel: DocumentCaptureViewModel
    )
    case documentBackCaptureInstructionScreen(
        documentCaptureViewModel: DocumentCaptureViewModel,
        skipDestination: NavigationDestination
    )
    case documentCaptureScreen(
        documentCaptureViewModel: DocumentCaptureViewModel
    )
    case documentCaptureProcessing
    case documentCaptureError(viewModel: DocumentCaptureViewModel)
    case documentCaptureComplete(viewModel: DocumentCaptureViewModel)
    case imagePicker(viewModel: DocumentCaptureViewModel)
    case documentConfirmation(viewModel: DocumentCaptureViewModel, image: UIImage)
}

public protocol ReflectiveEquatable: Equatable {}

public extension ReflectiveEquatable {
    var reflectedValue: String { String(reflecting: self) }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.reflectedValue == rhs.reflectedValue
    }
}
