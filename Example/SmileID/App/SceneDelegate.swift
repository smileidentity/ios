import Foundation
import netfox
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo _: UISceneSession,
    options _: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)

    UINavigationBar.appearance().titleTextAttributes = [
      NSAttributedString.Key.foregroundColor: UIColor.black
    ]
    NFX.sharedInstance().start()

    // NOTE TO PARTNERS: Normally, you would call SmileID.initialize() here
    window.rootViewController = UIHostingController(rootView: RootView())
    window.makeKeyAndVisible()
    self.window = window
  }
}
