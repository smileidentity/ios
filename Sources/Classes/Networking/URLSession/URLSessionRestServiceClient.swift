import Foundation

public protocol URLUploadSessionPublisher {
  var delegate: URLDelegate { get }
  func upload(
    request: URLRequest,
    data: Data?,
    _ callback: @escaping (Data?, URLResponse?, Error?) -> Void
  )
}

class URLSessionRestServiceClient: NSObject, RestServiceClient {
  typealias URLSessionResponse = (data: Data, response: URLResponse)
  let session: URLSessionPublisher
  let decoder = JSONDecoder()
  let requestTimeout: TimeInterval

  init(
    session: URLSessionPublisher,
    requestTimeout: TimeInterval = SmileID.defaultRequestTimeout
  ) {
    self.session = session
    self.requestTimeout = requestTimeout
  }

  func send<T: Decodable>(request: RestRequest) async throws -> T {
    do {
      let urlRequest = try request.getURLRequest()
      let urlSessionResponse = try await session.send(request: urlRequest)
      let data = try checkStatusCode(urlSessionResponse)
      return try decoder.decode(T.self, from: data)
    } catch {
      throw mapToAPIError(error)
    }
  }

  func upload(request: RestRequest) async throws -> Data {
    guard let requestBody = request.body else {
      throw SmileIDError.invalidRequestBody
    }

    do {
      let urlRequest = try request.getUploadRequest()
      let configuration = URLSessionConfiguration.default
      configuration.timeoutIntervalForRequest = requestTimeout
      let uploadSession = URLSession(configuration: configuration)

      let urlSessionResponse = try await uploadSession.upload(for: urlRequest, from: requestBody)
      return try checkStatusCode(urlSessionResponse)
    } catch {
      throw mapToAPIError(error)
    }
  }

  func multipart<T: Decodable>(request: RestRequest) async throws -> T {
    do {
      let urlRequest = try request.getURLRequest()
      let urlSessionResponse = try await session.send(request: urlRequest)
      let data = try checkStatusCode(urlSessionResponse)
      return try decoder.decode(T.self, from: data)
    } catch {
      throw mapToAPIError(error)
    }
  }

  private func checkStatusCode(_ urlSessionResponse: URLSessionResponse) throws -> Data {
    struct ErrorResponse: Codable {
      let error: String
    }
    let decoder = JSONDecoder()
    guard let httpResponse = urlSessionResponse.response as? HTTPURLResponse,
          httpResponse.isSuccess
    else {
      if let decodedError = try? decoder.decode(
        SmileIDErrorResponse.self,
        from: urlSessionResponse.data)
      {
        throw SmileIDError.api(decodedError.code, decodedError.message)
      }
      if let httpError = try? decoder.decode(
        ErrorResponse.self,
        from: urlSessionResponse.data)
      {
        throw SmileIDError.httpError(
          (urlSessionResponse.response as? HTTPURLResponse)?.statusCode ?? 500, httpError.error)
      }
      throw SmileIDError.httpError(
        (urlSessionResponse.response as? HTTPURLResponse)?.statusCode ?? 500,
        "Unknown error occurred")
    }

    return urlSessionResponse.data
  }
}

extension HTTPURLResponse {
  var isSuccess: Bool {
    let successCodes = Array(200...299)
    return successCodes.contains(statusCode)
  }
}

public class URLDelegate: NSObject, URLSessionTaskDelegate {
  let continuation: AsyncThrowingStream<UploadResponse, Error>.Continuation

  public init(continuation: AsyncThrowingStream<UploadResponse, Error>.Continuation) {
    self.continuation = continuation
  }

  public func urlSession(
    _: URLSession,
    task: URLSessionTask,
    didSendBodyData _: Int64,
    totalBytesSent _: Int64,
    totalBytesExpectedToSend _: Int64
  ) {
    continuation.yield(.progress(percentage: task.progress.fractionCompleted))
  }

  deinit {
    continuation.finish()
  }
}

public enum UploadResponse: Equatable {
  case progress(percentage: Double)
  case response(data: Data?)
}
