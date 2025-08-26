import Foundation

struct NetworkConfig {
	var environment: Environment
	var requestTimeout: TimeInterval
	var resourceTimeout: TimeInterval
	var cachePolicy: URLRequest.CachePolicy
	var waitsForConnectivity: Bool
	var additionalHeaders: [String: String]
	var lodRedactions: Set<String>

	init(
		environment: Environment,
		requestTimeout: TimeInterval = 30,
		resourceTimeout: TimeInterval = 60,
		cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData,
		waitsForConnectivity: Bool = true,
		additionalHeaders: [String : String] = [:],
		lodRedactions: Set<String> = [
			"authorization",
			"x-api-key",
			"-signature",
			InternalHeaders.needsAuth,
			InternalHeaders.needsEncryption,
			InternalHeaders.needsSignature
		]
	) {
		self.environment = environment
		self.requestTimeout = requestTimeout
		self.resourceTimeout = resourceTimeout
		self.cachePolicy = cachePolicy
		self.waitsForConnectivity = waitsForConnectivity
		self.additionalHeaders = additionalHeaders
		self.lodRedactions = lodRedactions
	}
}
