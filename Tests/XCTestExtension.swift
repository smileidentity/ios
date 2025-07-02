import Combine
import XCTest

extension XCTestCase {
  //     observe and await the result of a publisher into a dedicated XCTestCase method
  func await<T: Publisher>(
    _ publisher: T,
    timeout: TimeInterval = 10,
    file: StaticString = #file,
    line: UInt = #line
  ) throws -> T.Output {
    var result: Result<T.Output, Error>?
    let expectation = expectation(description: "Awaiting publisher")

    let cancellable = publisher.sink(
      receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
          result = .failure(error)
        case .finished:
          break
        }

        expectation.fulfill()
      },
      receiveValue: { value in
        result = .success(value)
      })

    waitForExpectations(timeout: timeout)
    cancellable.cancel()

    let unwrappedResult = try XCTUnwrap(
      result,
      "Awaited publisher did not produce any output",
      file: file,
      line: line)

    return try unwrappedResult.get()
  }
}
