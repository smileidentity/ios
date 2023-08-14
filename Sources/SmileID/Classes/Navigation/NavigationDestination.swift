import Foundation

enum NavigationDestination {
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
}
