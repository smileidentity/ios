import Combine
import SwiftUI

extension View {
    /// A backwards compatible wrapper for iOS 14 `onChange`
    @ViewBuilder func valueChanged<T: Equatable>(
        value: T,
        onChange: @escaping (T) -> Void
    ) -> some View {
        if #available(iOS 14.0, *) {
            self.onChange(of: value, perform: onChange)
        } else {
            onReceive(Just(value)) { value in
                onChange(value)
            }
        }
    }
}

public struct ModalModeKey: EnvironmentKey {
    public static let defaultValue = Binding<Bool>.constant(false)
}

extension EnvironmentValues {
    public var modalMode: Binding<Bool> {
        get { self[ModalModeKey.self] }
        set { self[ModalModeKey.self] = newValue }
    }
}
