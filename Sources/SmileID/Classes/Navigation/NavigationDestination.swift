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
}

public protocol ReflectiveEquatable: Equatable {}

public extension ReflectiveEquatable {
    var reflectedValue: String { String(reflecting: self) }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.reflectedValue == rhs.reflectedValue
    }
}
