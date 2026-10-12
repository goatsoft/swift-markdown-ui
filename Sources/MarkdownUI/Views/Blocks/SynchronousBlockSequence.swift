import SwiftUI

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
struct SynchronousBlockSequence<Element: Hashable, Content: View>: View {
  let data: [Indexed<Element>]
  let alignment: HorizontalAlignment
  let tight: Bool
  let spacing: MarkdownBlockSpacing
  let content: (Int, Element) -> Content

  var body: some View {
    TextStyleAttributesReader { attributes in
      BlockSequenceLayout(alignment: alignment, tight: tight) {
        ForEach(data, id: \.self) { element in
          content(element.index, element.value)
            .layoutValue(
              key: SynchronousBlockMarginKey.self,
              value: spacing.resolved(element.value, font: attributes.fontProperties))
        }
        // Measure SwiftUI's default padding instead of assuming a platform-specific value.
        // This final child is a probe, not part of the rendered block sequence.
        Color.clear.frame(width: 0, height: 0).padding(.top).hidden()
      }
    }
  }
}

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
struct SynchronousBlockMarginKey: LayoutValueKey {
  static let defaultValue = BlockMargin.unspecified
}

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
struct BlockSequenceLayout: Layout {
  let alignment: HorizontalAlignment
  let tight: Bool

  private func gap(_ index: Int, _ subviews: Subviews) -> CGFloat {
    guard index > 0 else { return 0 }
    let top = subviews[index][SynchronousBlockMarginKey.self].top
    let bottom = tight ? 0 : subviews[index - 1][SynchronousBlockMarginKey.self].bottom
    return [top, bottom].compactMap { $0 }.max()
      ?? (subviews.last?.sizeThatFits(.unspecified).height ?? 0)
  }

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    var size = CGSize.zero
    for index in 0..<max(0, subviews.count - 1) {
      let measured = subviews[index].sizeThatFits(
        ProposedViewSize(width: proposal.width, height: nil))
      size.width = max(size.width, measured.width)
      size.height += gap(index, subviews) + measured.height
    }
    return size
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    subviews.last?.place(at: bounds.origin, anchor: .topLeading, proposal: .zero)
    var y = bounds.minY
    for index in 0..<max(0, subviews.count - 1) {
      let view = subviews[index]
      let measured = view.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
      y += gap(index, subviews)
      let x =
        alignment == .trailing
        ? bounds.maxX - measured.width
        : alignment == .center ? bounds.midX - measured.width / 2 : bounds.minX
      view.place(
        at: CGPoint(x: x, y: y), anchor: .topLeading,
        proposal: ProposedViewSize(width: bounds.width, height: measured.height))
      y += measured.height
    }
  }
}
