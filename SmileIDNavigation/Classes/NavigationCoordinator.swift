import Foundation
import SwiftUI

public protocol NavigationCoordinator: ObservableObject {
  func navigate(to destination: NavigationDestination)
  func navigateUp()
  func popToRoot()
}

public enum NavigationDestination: Hashable, CaseIterable {
  case instructions
  case capture
  case preview
  case processing
}

public final class DefaultNavigationCoordinator: NavigationCoordinator {
  @Published public var path: [NavigationDestination] = []
  @Published public var currentDestination: NavigationDestination = .instructions

  public init() {}

  public func navigate(to destination: NavigationDestination) {
    path.append(destination)
    currentDestination = destination
  }

  public func navigateUp() {
    if !path.isEmpty {
      path.removeLast()
      currentDestination = path.last ?? .instructions
    }
  }

  public func popToRoot() {
    path.removeAll()
    currentDestination = .instructions
  }
}
