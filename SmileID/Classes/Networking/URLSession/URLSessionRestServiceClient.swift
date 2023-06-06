import Foundation
import Combine

public protocol URLUploadSessionPublisher {
    var delegate: URLDelegate { get }
    func upload(request: URLRequest, data: Data?, _ callback: @escaping (Data?, URLResponse?, Error?) -> Void)
}

class URLSessionRestServiceClient: NSObject, RestServiceClient {
    let session: URLSessionPublisher
    let uploadSession: URLUploadSessionPublisher
    let decoder = JSONDecoder()

    public init(session: URLSessionPublisher = URLSession.shared,
                uploadSession: URLUploadSessionPublisher = URLUploadSessionPublisherImplementation()) {
        self.session = session
        self.uploadSession = uploadSession
    }

    func send<T: Decodable>(request: RestRequest) -> AnyPublisher<T, Error> {
        do {
         let urlRequest = try request.getURLRequest()
            return session.send(request: urlRequest)
                .tryMap(checkStatusCode)
                .decode(type: T.self, decoder: decoder)
                .mapError(mapToAPIError)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    public func upload(request: RestRequest) -> AnyPublisher<UploadResponse, Error> {
        do {
            let urlRequest = try request.getUploadRequest()
            let subject = PassthroughSubject<UploadResponse, Error>()
            uploadSession.upload(request: urlRequest, data: request.body) { data, response, error in
                if let error = error {
                    print(error.localizedDescription)
                    subject.send(completion: .failure(error))
                    return
                }
                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    subject.send(.response(data: data))
                    return
                }
            }

            let uploadProgress = uploadSession.delegate.subject
            return uploadProgress
                .merge(with: subject)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private func checkSuccess(_ element: URLSession.DataTaskPublisher.Output) throws -> Bool {
        guard let httpResponse = element.response as? HTTPURLResponse,
              httpResponse.isSuccess else {
            throw APIError.httpStatus((element.response as? HTTPURLResponse)?.statusCode ?? 500, element.data)
        }
        return true
    }

    private func mapToAPIError(_ error: Error) -> APIError {
        if let decodingError = error as? DecodingError {
            return .decode(decodingError)
        } else if let error = error as? APIError {
            return error
        } else {
            return .unknown(error.localizedDescription)
        }
    }

    private func checkStatusCode(_ element: URLSession.DataTaskPublisher.Output) throws -> Data {
        guard let httpResponse = element.response as? HTTPURLResponse,
              httpResponse.isSuccess else {
            throw APIError.httpStatus((element.response as? HTTPURLResponse)?.statusCode ?? 500, element.data)
        }

        return element.data
    }
}

extension HTTPURLResponse {
    var isSuccess: Bool {
        let successCodes = Array(200...299)
        return successCodes.contains(statusCode)
    }
}

public class URLDelegate: NSObject, URLSessionTaskDelegate {

    var subject: PassthroughSubject<UploadResponse, Error>

    public init(subject: PassthroughSubject<UploadResponse, Error> = .init()) {
        self.subject = subject
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64,
                           totalBytesExpectedToSend: Int64) {
        subject.send(.progress(percentage: task.progress.fractionCompleted))
    }

}

public final class URLUploadSessionPublisherImplementation: URLUploadSessionPublisher {

    public let delegate: URLDelegate = URLDelegate()
    lazy var session = {
        URLSession(configuration: .default,
                   delegate: delegate,
                   delegateQueue: nil)
    }()

    public init() {}

    public func upload(request: URLRequest, data: Data?, _ callback: @escaping (Data?, URLResponse?, Error?) -> Void) {
        session.uploadTask(with: request, from: data) { data, response, error in
            callback(data, response, error)
        }.resume()
    }

}

public enum UploadResponse: Equatable {
    case progress(percentage: Double)
    case response(data: Data?)
}
