import Foundation

enum DataStoreError: Error {
    case batchDeleteError
    case saveContextError
    case saveItemError
    case unexpectedError(Error)
    case updateItemError
}
