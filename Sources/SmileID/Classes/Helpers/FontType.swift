import SwiftUI

public protocol FontType {
  /**
   Regular with size font.
   - Parameter size: A CGFloat for the font size.
   - Returns: A UIFont.
   */
  static func regular(with size: CGFloat) -> Font

  /**
   Medium with size font.
   - Parameter size: A CGFloat for the font size.
   - Returns: A UIFont.
   */
  static func medium(with size: CGFloat) -> Font

  /**
   Bold with size font.
   - Parameter size: A CGFloat for the font size.
   - Returns: A UIFont.
   */
  static func bold(with size: CGFloat) -> Font
}
