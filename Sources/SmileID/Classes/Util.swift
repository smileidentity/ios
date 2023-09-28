import Foundation

public func generateJobId() -> String {
    generateId("job-")
}

public func generateUserId() -> String {
    generateId("user-")
}

private func generateId(_ prefix: String) -> String {
    prefix + UUID().uuidString
}
