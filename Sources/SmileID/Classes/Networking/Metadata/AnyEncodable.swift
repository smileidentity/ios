import Foundation

/// A type-erased metadata value that can hold any Encodable type
struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void
    
    init<T: Encodable>(_ wrapped: T) {
        self.encodeClosure = wrapped.encode(to:)
    }
    
    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
