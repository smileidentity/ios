//
//  File.swift
//  
//
//  Created by Japhet Ndhlovu on 2023/05/09.
//

import SwiftUI

public protocol FontType {
  /**
   Regular with size font.
   - Parameter with size: A CGFLoat for the font size.
   - Returns: A UIFont.
   */
  static func regular(with size: CGFloat) -> Font

  /**
   Medium with size font.
   - Parameter with size: A CGFLoat for the font size.
   - Returns: A UIFont.
   */
  static func medium(with size: CGFloat) -> Font

  /**
   Bold with size font.
   - Parameter with size: A CGFLoat for the font size.
   - Returns: A UIFont.
   */
  static func bold(with size: CGFloat) -> Font
}
