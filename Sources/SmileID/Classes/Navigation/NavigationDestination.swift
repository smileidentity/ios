import UIKit

enum NavigationDestination: ReflectiveEquatable {
    case selfieInstructionScreen(selfieCaptureViewModel: SelfieCaptureViewModel,
                                 delegate: SmartSelfieResultDelegate?)
    case selfieCaptureScreen(selfieCaptureViewModel: SelfieCaptureViewModel,
                             delegate: SmartSelfieResultDelegate?)
    case documentFrontCaptureInstructionScreen(documentCaptureViewModel: DocumentCaptureViewModel,
                                               delegate: DocumentCaptureResultDelegate?)
    case documentBackCaptureInstructionScreen(documentCaptureViewModel: DocumentCaptureViewModel,
                                              delegate: DocumentCaptureResultDelegate?)
    case documentCaptureScreen(documentCaptureViewModel: DocumentCaptureViewModel,
                               delegate: DocumentCaptureResultDelegate?)
    case doucmentCaptureProcessing
    case documentCaptureError(viewModel: DocumentCaptureViewModel)
    case documentCaptureComplete(viewModel: DocumentCaptureViewModel)
    case imagePicker(viewModel: DocumentCaptureViewModel)
    case documentConfirmation(viewModel: DocumentCaptureViewModel, image: UIImage)
}

public protocol ReflectiveEquatable: Equatable {}

public extension ReflectiveEquatable {
    var reflectedValue: String { String(reflecting: self) }
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.reflectedValue == rhs.reflectedValue
    }
}
