import Foundation

enum NavigationDestination {
    case selfieInstructionScreen(selfieCaptureViewModel: SelfieCaptureViewModel,
                                 delegate: SmartSelfieResultDelegate?)
    case selfieCaptureScreen(selfieCaptureViewModel: SelfieCaptureViewModel,
                             delegate: SmartSelfieResultDelegate?)
    case documentCaptureInstructionScreen(documentCaptureViewModel: DocumentCaptureViewModel,
                                          delegate: DocumentCaptureResultDelegate?)
    case documentCaptureScreen(documentCaptureViewModel: DocumentCaptureViewModel,
                               delegate: DocumentCaptureResultDelegate?)
}
