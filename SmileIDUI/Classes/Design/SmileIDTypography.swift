import SwiftUI

public enum FontRole: CaseIterable {
  case pageHeading
  case sectionHeading
  case subHeading
  case cardTitle
  case cardSubTitle
  case body
  case button
}

/// Provider to resolver font per role, with Dynamic Type support
public protocol FontProvider {
  func font(for role: FontRole) -> Font
}

/// System font provider (Respects Dynamic Type automatically)
public struct SystemFontProvider: FontProvider {
  public init() {}

  public func font(for role: FontRole) -> Font {
    switch role {
    case .pageHeading:
      return .system(.largeTitle, design: .default)
    case .sectionHeading:
      return .system(.title, design: .default)
    case .subHeading:
      return .system(.headline, design: .default)
    case .cardTitle:
      return .system(.title, design: .default)
    case .cardSubTitle:
      return .system(.headline, design: .default)
    case .body:
      return .system(.body, design: .default)
    case .button:
      return .system(.headline, design: .default).weight(.semibold)
    }
  }
}

/// Custom font provider. Use `relativeTo:`to support Dynamic Type
public struct CustomFontProvider: FontProvider {
  public var familyName: String
  public var weights: [
    FontRole: (size: CGFloat, relativeTo: Font.TextStyle)
  ]

  public init(
    familyName: String,
    weights: [
      FontRole: (size: CGFloat, relativeTo: Font.TextStyle)
    ]
  ) {
    self.familyName = familyName
    self.weights = weights
  }

  public func font(for role: FontRole) -> Font {
    let spec = weights[role] ?? (16, .body)
    if #available(iOS 14.0, *) {
      return .custom(familyName, size: spec.size, relativeTo: spec.relativeTo)
    } else {
      return .custom(familyName, size: spec.size)
    }
  }
}

public struct SmileIDTypography {
  public var provider: FontProvider
  public init(provider: FontProvider) {
    self.provider = provider
  }

  public func font(_ role: FontRole) -> Font {
    provider.font(for: role)
  }
}
