import Foundation

enum DataStoreError: Error {
    case batchDeleteError
    case fetchError
    case saveContextError
    case saveItemError
    case unexpectedError(Error)
    case updateError
}

extension DataStoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .batchDeleteError:
            return "An error occurred while attempting to delete a batch of items."
        case .fetchError:
            return "An error occurred while fetching data."
        case .saveContextError:
            return "An error occurred while attempting to save the managed context."
        case .saveItemError:
            return "An error occurred while attempting to save an item."
        case .unexpectedError(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        case .updateError:
            return "An error occurred while attempting to update an item."
        }
    }
}
