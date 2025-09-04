import SwiftUI

public struct AdaptiveColor: Equatable, Hashable {
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
  public var primary: AdaptiveColor
  public var primaryForeground: AdaptiveColor
  public var background: AdaptiveColor
  public var cardBackground: AdaptiveColor
  public var titleText: AdaptiveColor
  public var cardText: AdaptiveColor
  public var stroke: AdaptiveColor
  public var warningFill: AdaptiveColor
  public var warningIcon: AdaptiveColor
  public var warningStroke: AdaptiveColor

  public init(
    primary: AdaptiveColor,
    primaryForeground: AdaptiveColor,
    background: AdaptiveColor,
    cardBackground: AdaptiveColor,
    titleText: AdaptiveColor,
    cardText: AdaptiveColor,
    stroke: AdaptiveColor,
    warningFill: AdaptiveColor,
    warningIcon: AdaptiveColor,
    warningStroke: AdaptiveColor
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
