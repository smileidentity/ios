import SwiftUI

public struct DefaultTheme: SmileIDTheme {
  public var colors: SmileIDColor
  public var typography: SmileIDTypography

  public init() {
    let base = SmileIDColor(
      primary: .init(
        standard: .init(
          light: Color(hex: "#151F72"),
          dark: Color(hex: "#4D88FF")
        )
      ),
      primaryForeground: .init(
        standard: .init(
          light: Color(hex: "#FFFFFF"),
          dark: Color(hex: "#FFFFFF")
        )
      ),
      background: .init(
        standard: .init(
          light: Color(hex: "#F9FAFB"),
          dark: Color(hex: "#1A1C23")
        )
      ),
      cardBackground: .init(
        standard: .init(
          light: Color(hex: "#FFFFFF"),
          dark: Color(hex: "#272A35")
        )
      ),
      titleText: .init(
        standard: .init(
          light: Color(hex: "#21232C"),
          dark: Color(hex: "#F2F2F2")
        )
      ),
      cardText: .init(
        standard: .init(
          light: Color(hex: "#5E646E"),
          dark: Color(hex: "#C2C5CB")
        )
      ),
      stroke: .init(
        standard: .init(
          light: Color(hex: "#EAECF0"),
          dark: Color(hex: "#EAECF0")
        )
      ),
      warningFill: .init(
        standard: .init(
          light: Color(hex: "#EF4343"),
          dark: Color(hex: "#EA2D2D")
        )
      ),
      warningIcon: .init(
        standard: .init(
          light: Color(hex: "#EF4343"),
          dark: Color(hex: "#FFFFFF")
        )
      ),
      warningStroke: .init(
        standard: .init(
          light: Color(hex: "#EF4343"),
          dark: Color(hex: "#9F0000")
        )
      )
    )

    self.colors = base
    self.typography = SmileIDTypography(
      spec: TypographySpec(
        pageHeading: FontSpec(source: .face(name: "DMSans-Bold"), size: 24, relativeTo: .headline),
        sectionHeading: FontSpec(source: .face(name: "DMSans-Bold"), size: 14, relativeTo: .headline),
        subHeading: FontSpec(source: .face(name: "DMSans-Medium"), size: 14, relativeTo: .subheadline),
        cardTitle: FontSpec(source: .face(name: "DMSans-Medium"), size: 14, relativeTo: .body),
        cardSubTitle: FontSpec(source: .face(name: "DMSans-Regular"), size: 12, relativeTo: .body),
        body: FontSpec(source: .face(name: "DMSans-Regular"), size: 12, relativeTo: .body),
        button: FontSpec(source: .face(name: "DMSans-Medium"), size: 16, relativeTo: .body)
      )
    )
  }
}
