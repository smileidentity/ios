import UIKit

class CopyableLabel: UILabel {
  override public var canBecomeFirstResponder: Bool {
    true
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    sharedInit()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    sharedInit()
  }

  func sharedInit() {
    isUserInteractionEnabled = true
    addGestureRecognizer(UILongPressGestureRecognizer(
      target: self,
      action: #selector(showMenu(sender:))))
  }

  @objc func copyToClipboard(_: Any?) {
    UIPasteboard.general.string = text
    UIMenuController.shared.hideMenu(from: self)
  }

  @objc func showMenu(sender _: Any?) {
    becomeFirstResponder()
    let menu = UIMenuController.shared
    if !menu.isMenuVisible {
      menu.showMenu(from: self, rect: bounds)
    }
  }

  override func canPerformAction(_ action: Selector, withSender _: Any?) -> Bool {
    action == #selector(copyToClipboard)
  }
}
