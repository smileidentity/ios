import Foundation

enum NetworkingFactory {
  static func makeDefault(
    environment: Environment,
    apiKey: String?,
    signingSecret: Data?,
    encryptionKey: Data?,
    tokenProvider: TokenProvider?,
    logger: NetworkLogger? = PrettyJSONLogger()
  ) -> APIClient {
    var config = NetworkConfig(environment: environment)
    if let apiKey {
      config.additionalHeaders["X-API-Key"] = apiKey
    }

    let sessionConfig = URLSessionConfigurationFactory.make(config: config)
    let transport = URLSessionHTTPClient(configuration: sessionConfig)

    // Compose middlewares:
    // logging -> retry -> auth -> encryption -> signing -> transport
    let loggingWrapped: HTTPClientProtocol = {
      guard let logger else { return transport }
      return LoggingMiddleware(
        next: transport,
        logger: logger,
        redacted: config.logRedactions
      )
    }()

    // TODO: Uncomment when RetryMiddleware is available.
    //		let retry = RetryMiddleware(
    //			next: loggingWrapped,
    //			policy: ExponentialBackoffPolicy()
    //		)

    let auth: HTTPClientProtocol = {
      if let tokenProvider {
        return AuthMiddleware(
          next: loggingWrapped,
          interceptor: AuthInterceptor(scheme: .bearer(tokenProvider))
        )
      }
      return loggingWrapped
    }()

    let encrypt: HTTPClientProtocol = {
      if let key = encryptionKey {
        return EncryptionMiddleware(
          next: encrypt,
          encryptor: AESGCMEncryptor(key: key),
          shouldEncrypt: { req in
            (req.value(forHTTPHeaderField: InternalHeaders.needsEncryption) ?? "").lowercased() == "body"
          }
        )
      }
      return auth
    }()

    let sign: HTTPClientProtocol = {
      if let secret = signingSecret {
        return SigningMiddleware(
          next: encrypt,
          signer: HMACSHA256Signer(secret: secret),
          shouldSign: { req in
            let value = (req.value(forHTTPHeaderField: InternalHeaders.needsSignature) ?? "").lowercased()
            return value == "header" || value == "body"
          }
        )
      }
      return encrypt
    }()

    let builder = DefaultRequestBuilder()
    return APIClient(
      config: config,
      builder: builder,
      client: sign
    )
  }
}
