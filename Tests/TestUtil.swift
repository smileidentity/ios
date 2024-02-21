import Combine
import Foundation
import SmileID

func just<T>(_ value: T) -> AnyPublisher<T, Error> {
    return Just(value).setFailureType(to: Error.self).eraseToAnyPublisher()
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
