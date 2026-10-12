import XCTest

@testable import MarkdownUI

final class MarkdownBlockSpacingTests: XCTestCase {
  private let font = FontProperties(size: 14)
  private let policy = MarkdownBlockSpacing([
    .paragraph: .init(top: .zero, bottom: .em(1)),
    .heading(1): .init(top: .rem(1.5), bottom: .rem(1)),
    .thematicBreak: .init(top: .em(2), bottom: .em(2)),
  ])

  func testContainersReduceEveryDescendantNotOnlyEdges() {
    let blocks: [BlockNode] = [.paragraph(content: []), .thematicBreak, .paragraph(content: [])]
    let item = RawListItem(children: blocks)
    let quote = BlockNode.blockquote(children: [.bulletedList(isTight: true, items: [item])])
    XCTAssertEqual(policy.resolved(quote, font: font), BlockMargin(top: 28, bottom: 28))
    XCTAssertEqual(policy.resolved(item, font: font), BlockMargin(top: 28, bottom: 28))
  }

  func testCodeOnlyContainerRetainsUnspecifiedMargins() {
    let quote = BlockNode.blockquote(children: [.codeBlock(fenceInfo: nil, content: "code")])
    XCTAssertEqual(policy.resolved(quote, font: font), .unspecified)
  }

  func testTightItemsKeepTheirOutwardParagraphMargin() {
    let item = RawListItem(children: [.paragraph(content: [])])
    let list = BlockNode.bulletedList(isTight: true, items: [item])
    XCTAssertEqual(policy.resolved(list, font: font), BlockMargin(top: 0, bottom: 14))
  }

  func testTaskAndListItemOverridesCombineWithDescendants() {
    var configured = policy
    configured.margins[.taskListItem] = .init(top: .rem(3))
    configured.margins[.listItem] = .init(bottom: .rem(4))
    let task = RawTaskListItem(isCompleted: false, children: [.paragraph(content: [])])
    XCTAssertEqual(configured.resolved(task, font: font), BlockMargin(top: 42, bottom: 14))
    XCTAssertEqual(
      configured.resolved(BlockNode.taskList(isTight: true, items: [task]), font: font),
      BlockMargin(top: 42, bottom: 14))
    let item = RawListItem(children: [.paragraph(content: [])])
    XCTAssertEqual(configured.resolved(item, font: font), BlockMargin(top: 0, bottom: 56))
  }

  func testRelativeMarginsRespectRootAndCurrentFontRounding() {
    let scaled = FontProperties(size: 15, scale: 1.5)
    XCTAssertEqual(
      policy.resolved(BlockNode.heading(level: 1, content: []), font: scaled),
      BlockMargin(top: 23, bottom: 15))
    XCTAssertEqual(
      policy.resolved(BlockNode.paragraph(content: []), font: scaled),
      BlockMargin(top: 0, bottom: 23))
  }
}
