import Foundation

enum DataStoreError: Error {
    case batchDeleteError
    case fetchError
    case saveContextError
    case saveItemError
    case unexpectedError(Error)
    case updateError
}
