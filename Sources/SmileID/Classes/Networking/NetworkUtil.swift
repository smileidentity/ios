import Combine
import CommonCrypto
import Foundation

public func calculateSignature(timestamp: String) throws -> String {
    guard let apiKey = SmileID.apiKey else {
        throw NSError(
            domain: "",
            code: 0,
            userInfo: [
                NSLocalizedDescriptionKey:
                """
                API key not set. If using the authToken from smile_config.json, \
                ensure you have set the signature/timestamp properties on the request from the \
                values returned by SmileID.authenticate.signature/timestamp
                """
            ]
        )
    }
    let hashContent = "\(timestamp)\(SmileID.config.partnerId)sid_request"
    guard let hmac = hashContent.hmac(algorithm: .SHA256, key: apiKey) else {
        throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "HMAC calculation failed"])
    }

    return hmac.base64EncodedString()
}

extension String {
    func hmac(algorithm: CryptoAlgorithm, key: String) -> Data? {
        let str = cString(using: String.Encoding.utf8)
        let strLen = Int(lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = algorithm.digestLength
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        let keyStr = key.cString(using: String.Encoding.utf8)
        let keyLen = Int(key.lengthOfBytes(using: String.Encoding.utf8))

        CCHmac(algorithm.HMACAlgorithm, keyStr!, keyLen, str!, strLen, result)

        return Data(bytes: result, count: digestLen)
    }
}

enum CryptoAlgorithm {
    case SHA256

    var HMACAlgorithm: CCHmacAlgorithm {
        switch self {
        case .SHA256:
            return CCHmacAlgorithm(kCCHmacAlgSHA256)
        }
    }

    var digestLength: Int {
        switch self {
        case .SHA256:
            return Int(CC_SHA256_DIGEST_LENGTH)
        }
    }
}

public extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var finishedWithoutValue = true
            cancellable = first()
                .sink { result in
                    switch result {
                    case .finished:
                        if finishedWithoutValue {
                            continuation.resume(
                                throwing: SmileIDError.unknown("Publisher finished without value")
                            )
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    finishedWithoutValue = false
                    continuation.resume(with: .success(value))
                }
        }
    }
}
