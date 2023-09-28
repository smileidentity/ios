import Foundation

@propertyWrapper struct Injected<DependencyType> {

    var wrappedValue: DependencyType { instance }
    private let instance: DependencyType

    public init() {
        instance = DependencyAutoResolver.resolve(DependencyType.self)
    }
}
