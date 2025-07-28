import Foundation

@propertyWrapper struct Injected<DependencyType> {
  var wrappedValue: DependencyType { instance }
  private let instance: DependencyType

  init() {
    instance = DependencyAutoResolver.resolve(DependencyType.self)
  }
}
