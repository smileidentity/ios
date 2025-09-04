import Foundation
import SmileID

@objc public class SmileIDObjCBridge: NSObject {
  @objc public static func initializeSDK() {
    // Load config from smile_config.json
    let config = SmileID.getConfig(from: "smile_config")

    // Initialize SmileID with the config
    SmileID.initialize(
      config: config,
      useSandbox: true,
      enableCrashReporting: true,
      requestTimeout: 60.0
    )
  }

  @objc public static func initializeSDKWithConfig(
    partnerId: String,
    authToken: String,
    prodLambdaUrl: String,
    testLambdaUrl: String,
    useSandbox: Bool,
    enableCrashReporting: Bool,
    requestTimeout: TimeInterval
  ) {
    let config = Config(
      partnerId: partnerId,
      authToken: authToken,
      prodLambdaUrl: prodLambdaUrl,
      testLambdaUrl: testLambdaUrl
    )

    SmileID.initialize(
      config: config,
      useSandbox: useSandbox,
      enableCrashReporting: enableCrashReporting,
      requestTimeout: requestTimeout
    )
  }
}
