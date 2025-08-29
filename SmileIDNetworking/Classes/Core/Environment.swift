import Foundation

struct Environment: Equatable {
  let name: String
  let baseURL: URL

  init(
    name: String,
    baseURL: URL
  ) {
    self.name = name
    self.baseURL = baseURL
  }

  static func sandbox(_ url: URL) -> Environment {
    .init(name: "sandbox", baseURL: url)
  }

  static func production(_ url: URL) -> Environment {
    .init(name: "production", baseURL: url)
  }
}
