import SwiftUI

public struct DynamicColor: Equatable, Hashable {
  public struct Pair: Equatable, Hashable {
    public var light: Color
    public var dark: Color

    public init(light: Color, dark: Color) {
      self.light = light
      self.dark = dark
    }

    public func resolve(_ scheme: ColorScheme) -> Color {
      scheme == .dark ? dark : light
    }
  }
}

public struct SmileIDColor: Equatable {
  public var primary: DynamicColor
  public var primaryForeground: DynamicColor
  public var background: DynamicColor
  public var cardBackground: DynamicColor
  public var titleText: DynamicColor
  public var cardText: DynamicColor
  public var stroke: DynamicColor
  public var warningFill: DynamicColor
  public var warningIcon: DynamicColor
  public var warningStroke: DynamicColor
}
