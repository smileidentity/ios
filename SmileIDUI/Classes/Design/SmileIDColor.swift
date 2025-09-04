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

  public var standard: Pair
  public var highContrast: Pair?

  public init(
    standard: Pair,
    highContrast: Pair? = nil
  ) {
    self.standard = standard
    self.highContrast = highContrast
  }

  @inlinable public func resolve(
    _ scheme: ColorScheme,
    contrast: ColorSchemeContrast
  ) -> Color {
    if contrast == .increased,
       let highContrast {
      return highContrast.resolve(scheme)
    }
    return standard.resolve(scheme)
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

  public init(
    primary: DynamicColor,
    primaryForeground: DynamicColor,
    background: DynamicColor,
    cardBackground: DynamicColor,
    titleText: DynamicColor,
    cardText: DynamicColor,
    stroke: DynamicColor,
    warningFill: DynamicColor,
    warningIcon: DynamicColor,
    warningStroke: DynamicColor
  ) {
    self.primary = primary
    self.primaryForeground = primaryForeground
    self.background = background
    self.cardBackground = cardBackground
    self.titleText = titleText
    self.cardText = cardText
    self.stroke = stroke
    self.warningFill = warningFill
    self.warningIcon = warningIcon
    self.warningStroke = warningStroke
  }
}
