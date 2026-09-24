import SwiftUI
import WMFData

struct WMFInterestArticleGridView: View {

    let viewModels: [WMFInterestArticleCardViewModel]
    let theme: WMFTheme
    /// Viewport (not content) size, used to pick the column count the way the article tabs
    /// grid does — more columns on iPad and in landscape.
    let viewportSize: CGSize
    let onTap: (WMFInterestArticleCardViewModel) -> Void

    // At accessibility sizes half-width columns word-break the scaled titles, so the grid
    // collapses to a single full-width column.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columnCount: Int {
        WMFCardGridColumns.count(for: viewportSize, isAccessibilitySize: dynamicTypeSize.isAccessibilitySize, idiom: UIDevice.current.userInterfaceIdiom)
    }

    /// Distributes cards into `columnCount` masonry columns, each card going to the currently
    /// shortest column so the columns end up roughly level.
    private func columns(count: Int) -> [[WMFInterestArticleCardViewModel]] {
        guard count > 1 else { return [viewModels] }

        var columns: [[WMFInterestArticleCardViewModel]] = Array(repeating: [], count: count)
        var heights = [CGFloat](repeating: 0, count: count)

        for vm in viewModels {
            var shortest = 0
            for index in 1..<count where heights[index] < heights[shortest] {
                shortest = index
            }
            columns[shortest].append(vm)
            heights[shortest] += estimatedHeight(for: vm)
        }
        return columns
    }

    private func estimatedHeight(for vm: WMFInterestArticleCardViewModel) -> CGFloat {
        let imageHeight: CGFloat = vm.thumbnailURL != nil ? 100 : 0
        let titleLines = max(1, Int(ceil(Double(vm.displayTitle.removingHTML.count) / 18.0)))
        let titleHeight = CGFloat(titleLines) * 20
        let descriptionHeight: CGFloat
        if let desc = vm.description {
            let lines = max(1, Int(ceil(Double(desc.count) / 20.0)))
            descriptionHeight = CGFloat(lines) * 16
        } else {
            descriptionHeight = 0
        }
        return imageHeight + titleHeight + descriptionHeight + 32
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(Array(columns(count: columnCount).enumerated()), id: \.offset) { _, items in
                column(items)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func column(_ items: [WMFInterestArticleCardViewModel]) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(items) { vm in
                WMFInterestArticleCardView(viewModel: vm, theme: theme)
                    .onTapGesture {
                        onTap(vm)
                    }
            }
        }
    }
}

private struct WMFInterestArticleCardView: View {

    // Capped by the interests screen; fonts resolve against the capped value.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // Scales with Dynamic Type so the image band keeps its proportion of the card.
    @ScaledMetric private var imageHeight: CGFloat = 100

    @ObservedObject var viewModel: WMFInterestArticleCardViewModel
    let theme: WMFTheme
    
    private var subheadlineStyles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.boldSubheadline), boldFont: WMFFont.for(.boldSubheadline), italicsFont: WMFFont.for(.boldItalicSubheadline), boldItalicsFont: WMFFont.for(.boldItalicSubheadline), color: theme.text, linkColor: theme.link, lineSpacing: 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let uiImage = viewModel.uiImage {
                // The container drives layout; scaledToFill images would otherwise report
                // their own width and inflate the card beyond its column width
                Color.clear
                    .frame(height: imageHeight)
                    .overlay(
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    )
                    .clipped()
                    .contentShape(Rectangle())
            }
            // Baseline (not frame-bottom) alignment so the checkmark sits on the last line of
            // text rather than below its descender space.
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                VStack(alignment: .leading, spacing: 4) {
                    WMFHtmlText(html: viewModel.displayTitle, styles: subheadlineStyles)
                    if let description = viewModel.description {
                        Text(description)
                            .font(Font(WMFFont.for(.callout, sized: dynamicTypeSize)))
                            .foregroundStyle(Color(uiColor: theme.secondaryText))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                checkmark
            }
            .padding(8)
            .background(viewModel.isSelected ? Color(uiColor: theme.addition) : Color.clear)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: theme.paperBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(uiColor: theme.newBorder), lineWidth: 1)
        )
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(viewModel.isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// Always laid out — only its visibility changes — so the title/description are sized
    /// around it (long titles used to run underneath) and selecting doesn't reflow the card.
    @ViewBuilder
    private var checkmark: some View {
        if let image = WMFSFSymbolIcon.for(symbol: .checkmark, font: .subheadline, compatibleWith: dynamicTypeSize.wmfTraitCollection) {
            Image(uiImage: image)
                .foregroundStyle(Color(uiColor: theme.link))
                .opacity(viewModel.isSelected ? 1 : 0)
        }
    }

    private var accessibilityLabel: String {
        [viewModel.displayTitle.removingHTML, viewModel.description]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
