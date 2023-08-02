import Combine
import SwiftUI

extension View {
    func handleNavigation(_ navigationDirection: Binding<NavigationDirection?>,
                          onDismiss: ((NavigationDestination) -> Void)? = nil) -> some View
    {
        modifier(NavigationHandler(navigationDirection: navigationDirection,
                                   onDismiss: onDismiss))
    }
}

extension View {
    /// A backwards compatible wrapper for iOS 14 `onChange`
    @ViewBuilder func valueChanged<T: Equatable>(value: T, onChange: @escaping (T) -> Void) -> some View {
        if #available(iOS 14.0, *) {
            self.onChange(of: value, perform: onChange)
        } else {
            onReceive(Just(value)) { value in
                onChange(value)
            }
        }
    }
}

struct NavigationHandler: ViewModifier {
    @Binding
    var navigationDirection: NavigationDirection?
    var onDismiss: ((NavigationDestination) -> Void)?
    @State
    private var destination: NavigationDestination?
    @State
    private var sheetActive = false
    @State
    private var linkActive = false
    @Environment(\.presentationMode) var presentation
    let viewFactory = ViewFactory()

    func body(content: Content) -> some View {
        content
            .background(
                EmptyView()
                    .sheet(isPresented: $sheetActive, onDismiss: {
                        if let destination = destination {
                            onDismiss?(destination)
                        }
                    }) {
                        buildDestination(destination)
                    }
            )
            .background(
                NavigationLink(destination: buildDestination(destination), isActive: $linkActive) {
                    EmptyView()
                }
            )
            .valueChanged(value: navigationDirection, onChange: { direction in
                switch direction {
                case let .forward(destination, style):
                    self.destination = destination
                    switch style {
                    case .present:
                        sheetActive = true
                    case .push:
                        linkActive = true
                    }
                case .back:
                    presentation.wrappedValue.dismiss()
                case .none:
                    break
                }
                navigationDirection = nil
            })
    }

    @ViewBuilder
    private func buildDestination(_ destination: NavigationDestination?) -> some View {
        if let destination = destination {
            viewFactory.makeView(destination)
        } else {
            EmptyView()
        }
    }
}
