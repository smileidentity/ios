import SwiftUI

/// Describes the source of a font
public enum FontSource {
  case face(name: String) // specific PostScript face, e.g., "DMSans-Bold"
  case family(name: String) // family name; system decides the face
}

/// Strongly-typed specification for a given role
public struct FontSpec {
  public var source: FontSource
  public var size: CGFloat
  public var relativeTo: Font.TextStyle

  public init(
    source: FontSource,
    size: CGFloat,
    relativeTo: Font.TextStyle
  ) {
    self.source = source
    self.size = size
    self.relativeTo = relativeTo
  }

  public func font() -> Font {
    switch source {
    case .face(let name), .family(let name):
      if #available(iOS 14.0, *) {
        return .custom(name, size: size, relativeTo: relativeTo)
      } else {
        return .custom(name, size: size)
      }
    }
  }
}

/// Full typography spec; explicit value per role
public struct TypographySpec {
  public var pageHeading: FontSpec
  public var sectionHeading: FontSpec
  public var subHeading: FontSpec
  public var cardTitle: FontSpec
  public var cardSubTitle: FontSpec
  public var body: FontSpec
  public var button: FontSpec

  public init(
    pageHeading: FontSpec,
    sectionHeading: FontSpec,
    subHeading: FontSpec,
    cardTitle: FontSpec,
    cardSubTitle: FontSpec,
    body: FontSpec,
    button: FontSpec
  ) {
    self.pageHeading = pageHeading
    self.sectionHeading = sectionHeading
    self.subHeading = subHeading
    self.cardTitle = cardTitle
    self.cardSubTitle = cardSubTitle
    self.body = body
    self.button = button
  }
}

/// Public facade exposing fonts for each role directly
public struct SmileIDTypography {
  public var spec: TypographySpec

  public init(spec: TypographySpec) { self.spec = spec }

  public var pageHeading: Font { spec.pageHeading.font() }
  public var sectionHeading: Font { spec.sectionHeading.font() }
  public var subHeading: Font { spec.subHeading.font() }
  public var cardTitle: Font { spec.cardTitle.font() }
  public var cardSubTitle: Font { spec.cardSubTitle.font() }
  public var body: Font { spec.body.font() }
  public var button: Font { spec.button.font() }
}
