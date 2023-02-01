import Foundation

protocol DependencyRegisterer {
    func register<T>(_ dependency: T.Type, creation: @escaping () -> T)
    func register<T>(singleton: T.Type, creation: @escaping () -> T)
}
