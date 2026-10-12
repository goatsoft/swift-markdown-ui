#if os(macOS)
  import AppKit
  import SwiftUI
  import XCTest
  @testable import MarkdownUI

  @available(macOS 13, *)
  @MainActor final class BlockSequenceLayoutTests: XCTestCase {
    func testContentWidthRemainsFiniteForFiniteAndUnlimitedOffers() {
      let controller = NSHostingController(rootView: blocks(tight: false))
      for offered: CGFloat in [600, .infinity] {
        let size = controller.sizeThatFits(in: CGSize(width: offered, height: CGFloat.infinity))
        XCTAssertEqual(size.width, 26)
        XCTAssertEqual(size.height, 80)
        XCTAssertTrue(size.width.isFinite)
      }
    }

    func testTightListUsesCurrentTopInsteadOfPreviousBottom() {
      let controller = NSHostingController(rootView: blocks(tight: true))
      XCTAssertEqual(controller.sizeThatFits(in: CGSize(width: 600, height: CGFloat.infinity)).height, 74)
    }

    func testUnspecifiedGapUsesProbeAndProbeIsExcludedFromContentSize() {
      let controller = NSHostingController(
        rootView: BlockSequenceLayout(alignment: .leading, tight: false) {
          Color.clear.frame(width: 26, height: 10)
          Color.clear.frame(width: 18, height: 20)
          Color.clear.frame(width: 0, height: 7).hidden()
        })
      let size = controller.sizeThatFits(in: CGSize(width: 600, height: CGFloat.infinity))
      XCTAssertEqual(size, CGSize(width: 26, height: 37))
      let empty = NSHostingController(
        rootView: BlockSequenceLayout(alignment: .leading, tight: false) {
          Color.clear.frame(width: 0, height: 7).hidden()
        })
      XCTAssertEqual(empty.sizeThatFits(in: CGSize(width: 600, height: CGFloat.infinity)), .zero)
    }

    func testPlacementMatchesMeasurementAndHorizontalAlignment() async throws {
      for alignment in [HorizontalAlignment.leading, .center, .trailing] {
        var frames: [Int: CGRect] = [:]
        let host = NSHostingView(
          rootView: BlockSequenceLayout(alignment: alignment, tight: false) {
            measuredBlock(0, width: 26, height: 10)
              .layoutValue(key: SynchronousBlockMarginKey.self, value: BlockMargin(top: nil, bottom: 12))
            measuredBlock(1, width: 18, height: 20)
              .layoutValue(key: SynchronousBlockMarginKey.self, value: BlockMargin(top: 6, bottom: nil))
            Color.clear.frame(width: 0, height: 7).hidden()
          }
          .coordinateSpace(name: "blocks")
          .onPreferenceChange(BlockFrames.self) { frames = $0 })
        host.frame = CGRect(x: 0, y: 0, width: 26, height: 42)
        host.layoutSubtreeIfNeeded()
        try await Task.sleep(nanoseconds: 100_000_000)
        host.layoutSubtreeIfNeeded()
        let first = try XCTUnwrap(frames[0])
        let second = try XCTUnwrap(frames[1])
        XCTAssertEqual(first.minY, 0)
        XCTAssertEqual(second.minY, 22)
        XCTAssertEqual(second.maxY, 42)
        XCTAssertEqual(second.minX, alignment == .leading ? 0 : alignment == .center ? 4 : 8)
      }
    }

    private func blocks(tight: Bool) -> some View {
      BlockSequenceLayout(alignment: .leading, tight: tight) {
        Color.clear.frame(width: 26, height: 10)
          .layoutValue(key: SynchronousBlockMarginKey.self, value: BlockMargin(top: 100, bottom: 12))
        Color.clear.frame(width: 18, height: 20)
          .layoutValue(key: SynchronousBlockMarginKey.self, value: BlockMargin(top: 6, bottom: 4))
        Color.clear.frame(width: 12, height: 30)
          .layoutValue(key: SynchronousBlockMarginKey.self, value: BlockMargin(top: 8, bottom: nil))
        Color.clear.frame(width: 0, height: 7).hidden()
      }
    }

    private func measuredBlock(_ id: Int, width: CGFloat, height: CGFloat) -> some View {
      Color.clear.frame(width: width, height: height)
        .background(GeometryReader { geometry in
          Color.clear.preference(key: BlockFrames.self, value: [id: geometry.frame(in: .named("blocks"))])
        })
    }
  }

  private struct BlockFrames: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
      value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
  }
#endif
