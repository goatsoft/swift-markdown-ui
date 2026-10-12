import SwiftUI

/// Explicit block margins for synchronous layout on modern SwiftUI.
///
/// The supplied margins must match the block styles. When enabled, these values replace
/// margin preferences for spacing; preferences cannot be read synchronously during layout.
/// Container margins include the maximum margins of every descendant, like MarkdownUI's
/// preference-based renderer. Styles that add content or change inherited font sizes need
/// a matching policy, or should keep the default preference-based renderer.
public struct MarkdownBlockSpacing: Hashable {
  public enum Kind: Hashable {
    case paragraph, htmlBlock
    case heading(Int)
    case codeBlock, table, thematicBreak
    case blockquote, list, listItem, taskListItem
  }

  public struct Margins: Hashable {
    public var top: RelativeSize?
    public var bottom: RelativeSize?

    public init(top: RelativeSize? = nil, bottom: RelativeSize? = nil) {
      self.top = top
      self.bottom = bottom
    }
  }

  public var margins: [Kind: Margins]

  public init(_ margins: [Kind: Margins]) {
    self.margins = margins
  }

  func resolved<T>(_ value: T, font: FontProperties?) -> BlockMargin {
    if let block = value as? BlockNode { return resolved(block, font: font) }
    if let item = value as? RawListItem {
      return resolved(item.children, own: .listItem, font: font)
    }
    if let item = value as? RawTaskListItem {
      return resolved(item.children, own: .taskListItem, font: font)
    }
    return .unspecified
  }

  private func own(_ kind: Kind, font: FontProperties?) -> BlockMargin {
    BlockMargin(
      top: margins[kind]?.top?.points(relativeTo: font),
      bottom: margins[kind]?.bottom?.points(relativeTo: font))
  }

  private func combined(_ first: BlockMargin, _ second: BlockMargin) -> BlockMargin {
    BlockMargin(
      top: [first.top, second.top].compactMap { $0 }.max(),
      bottom: [first.bottom, second.bottom].compactMap { $0 }.max())
  }

  private func resolved(_ children: [BlockNode], own kind: Kind, font: FontProperties?)
    -> BlockMargin
  {
    children.reduce(own(kind, font: font)) { combined($0, resolved($1, font: font)) }
  }

  private func resolved(_ block: BlockNode, font: FontProperties?) -> BlockMargin {
    switch block {
    case .paragraph: return own(.paragraph, font: font)
    case .htmlBlock: return own(.htmlBlock, font: font)
    case .heading(let level, _): return own(.heading(level), font: font)
    case .codeBlock: return own(.codeBlock, font: font)
    case .table: return own(.table, font: font)
    case .thematicBreak: return own(.thematicBreak, font: font)
    case .blockquote(let children): return resolved(children, own: .blockquote, font: font)
    case .bulletedList(_, let items), .numberedList(_, _, let items):
      return items.reduce(own(.list, font: font)) {
        combined($0, resolved($1.children, own: .listItem, font: font))
      }
    case .taskList(_, let items):
      return items.reduce(own(.list, font: font)) {
        combined($0, resolved($1.children, own: .taskListItem, font: font))
      }
    }
  }
}

extension View {
  /// Uses explicit margins to lay out all block sequences in a single synchronous pass.
  /// Omit this modifier to retain the standard margin-preference renderer.
  @available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
  public func markdownBlockSpacing(_ spacing: MarkdownBlockSpacing) -> some View {
    environment(\.synchronousBlockSpacing, spacing)
  }
}

private struct SynchronousBlockSpacingKey: EnvironmentKey {
  static let defaultValue: MarkdownBlockSpacing? = nil
}

extension EnvironmentValues {
  var synchronousBlockSpacing: MarkdownBlockSpacing? {
    get { self[SynchronousBlockSpacingKey.self] }
    set { self[SynchronousBlockSpacingKey.self] = newValue }
  }
}
