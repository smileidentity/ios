import Foundation

@propertyWrapper public struct Injected<DependencyType> {

    public var wrappedValue: DependencyType {
        return instance
    }

    private let instance: DependencyType

    public init() {
        instance = DependencyAutoResolver.resolve(DependencyType.self)
    }
}
