import Foundation

final class URLSessionHTTPClient: HTTPClientProtocol {
	private let session: URLSession

	init(
		configuration: URLSessionConfiguration,
		delegate: URLSessionDelegate? = nil
	) {
		self.session = URLSession(
			configuration: configuration,
			delegate: delegate,
			delegateQueue: nil
		)
	}

	func send(
		_ request: URLRequest
	) async throws -> (Data, HTTPURLResponse) {
		do {
			let (data, response) = try await session.data(for: request)
			guard let http = response as? HTTPURLResponse else {
				throw NetworkError.nonHTTPResponse
			}
			return (data, http)
		} catch let error as URLError {
			throw NetworkError.transport(error)
		} catch {
			throw error
		}
	}
}

enum URLSessionConfigurationFactory {
	static func make(config: NetworkConfig) -> URLSessionConfiguration {
		let configuration = URLSessionConfiguration.ephemeral
		configuration.timeoutIntervalForRequest = config.requestTimeout
		configuration.timeoutIntervalForResource = config.resourceTimeout
		configuration.requestCachePolicy = config.cachePolicy
		configuration.waitsForConnectivity = config.waitsForConnectivity
		configuration.httpAdditionalHeaders = ["Accept": "application/json"]
		return configuration
	}
}
