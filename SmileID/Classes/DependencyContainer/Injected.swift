import Foundation

@propertyWrapper struct Injected<DependencyType> {

    var wrappedValue: DependencyType {
        return instance
    }

    private let instance: DependencyType

    public init() {
        instance = DependencyAutoResolver.resolve(DependencyType.self)
    }
}
