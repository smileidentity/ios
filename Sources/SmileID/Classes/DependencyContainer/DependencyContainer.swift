import Foundation

final class DependencyContainer {

    static var shared = DependencyContainer()

    private var dependencies: [String: () -> Any] = [:]
    init() {}

}

extension DependencyContainer: DependencyRegisterer {

    func register<T>(_ dependency: T.Type, creation: @escaping () -> T) {
        let dependencyKey = key(forType: dependency)
        guard !dependencies.keys.contains(dependencyKey) else {
            preconditionFailure("\(dependencyKey) already registered in container.")
        }

        dependencies[dependencyKey] = creation
    }

    func register<T>(singleton: T.Type, creation: @escaping () -> T) {
        let dependencyKey = key(forType: singleton)
        guard !dependencies.keys.contains(dependencyKey) else {
            preconditionFailure("Singleton \(dependencyKey) already registered in container.")
        }

        dependencies[dependencyKey] = SingletonDependency(creation: creation).get
    }
}

extension DependencyContainer: DependencyResolver {

    func has<T>(_ dependency: T.Type) -> Bool {
        let dependencyKey = key(forType: dependency)
        return dependencies.keys.contains(dependencyKey)
    }

    func resolve<T>(_ dependency: T.Type) -> T {
        let dependencyKey = key(forType: dependency)
        guard let dependencyMethod = dependencies[dependencyKey] else {
            preconditionFailure("\(dependencyKey) is not registered in the container.")
        }

        guard let instance = dependencyMethod() as? T else {
            preconditionFailure("\(dependencyKey) registration creates invalid dependency.")
        }

        return instance
    }
}

private extension DependencyContainer {
    func key<T>(forType type: T.Type) -> String {
        String(describing: type)
    }
}

private class SingletonDependency {
    var instance: Any?
    var creation: () -> Any

    init(creation: @escaping () -> Any) {
        self.creation = creation
    }

    func get() -> Any {
        if let instance = instance {
            return instance
        }

        let instance = creation()
        self.instance = instance
        return instance
    }
}
