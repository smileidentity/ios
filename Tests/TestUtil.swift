import Combine
import Foundation
import SmileID
import XCTest

func just<T>(_ value: T) -> AnyPublisher<T, Error> {
    return Just(value).setFailureType(to: Error.self).eraseToAnyPublisher()
}

func justError<T>(_ error: Error, _ type: T.Type) -> AnyPublisher<T, Error> {
    return Fail(error: error).eraseToAnyPublisher()
}

func initSdk() {
    SmileID.initialize(config: Config(
        partnerId: "id",
        authToken: "token",
        prodUrl: "url", testUrl: "url",
        prodLambdaUrl: "url",
        testLambdaUrl: "url"
    ))
}

/// Asserts that an asynchronous expression throws an error.
/// (Intended to function as a drop-in asynchronous version of `XCTAssertThrowsError`.)
///
/// Example usage:
///
///     await assertThrowsAsyncError(
///         try await sut.function()
///     ) { error in
///         XCTAssertEqual(error as? MyError, MyError.specificError)
///     }
///
/// - Parameters:
///   - expression: An asynchronous expression that can throw an error.
///   - message: An optional description of a failure.
///   - file: The file where the failure occurs.
///     The default is the filename of the test case where you call this function.
///   - line: The line number where the failure occurs.
///     The default is the line number where you call this function.
///   - errorHandler: An optional handler for errors that expression throws.
func assertThrowsAsyncError<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        // expected error to be thrown, but it was not
        let customMessage = message()
        if customMessage.isEmpty {
            XCTFail("Asynchronous call did not throw an error.", file: file, line: line)
        } else {
            XCTFail(customMessage, file: file, line: line)
        }
    } catch {
        errorHandler(error)
    }
}
