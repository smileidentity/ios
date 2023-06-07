import Foundation

protocol DependencyResolver {
    func has<T>(_ dependency: T.Type) -> Bool
    func resolve<T>(_ dependency: T.Type) -> T
}
