#if !os(tvOS)
  import SwiftUI
  import XCTest

  @testable import MarkdownUI

  final class FontPropertiesTests: XCTestCase {
    func testFontWithProperties() {
      // given
      var fontProperties = FontProperties()

      // The library targets macOS 12 / iOS 15, where system fonts default to regular.
      // Newer test runners select an overload whose omitted weight means inherited weight.
      // Specify the expected weight so both sides compare the same font contract.
      // then
      XCTAssertEqual(
        Font.system(size: FontProperties.defaultSize, weight: .regular, design: .default),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(family: .custom("Menlo"))

      // then
      XCTAssertEqual(
        Font.custom("Menlo", fixedSize: FontProperties.defaultSize),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(familyVariant: .monospaced)

      // then
      XCTAssertEqual(
        Font.system(size: FontProperties.defaultSize, weight: .regular, design: .default)
          .monospaced(),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(capsVariant: .lowercaseSmallCaps)

      // then
      XCTAssertEqual(
        Font.system(size: FontProperties.defaultSize, weight: .regular, design: .default)
          .lowercaseSmallCaps(),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(digitVariant: .monospaced)

      // then
      XCTAssertEqual(
        Font.system(size: FontProperties.defaultSize, weight: .regular, design: .default)
          .monospacedDigit(),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(style: .italic)

      // then
      XCTAssertEqual(
        Font.system(size: FontProperties.defaultSize, weight: .regular, design: .default).italic(),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(weight: .heavy)

      // then
      XCTAssertEqual(
        Font.system(size: FontProperties.defaultSize, weight: .regular, design: .default).weight(
          .heavy),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(size: 42)

      // then
      XCTAssertEqual(
        Font.system(size: 42, weight: .regular, design: .default),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(scale: 1.5)

      // then
      XCTAssertEqual(
        Font.system(
          size: round(FontProperties.defaultSize * 1.5), weight: .regular, design: .default),
        Font.withProperties(fontProperties)
      )
    }
  }
#endif
