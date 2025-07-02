import Foundation

protocol DependencyResolver {
  func has(_ dependency: (some Any).Type) -> Bool
  func resolve<T>(_ dependency: T.Type) -> T
}
