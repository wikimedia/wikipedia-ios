// TODO: This is temporary UI — article grid and card views are placeholders pending final design.

import SwiftUI
import WMFData

struct WMFInterestArticleGridView: View {

    let viewModels: [WMFInterestArticleCardViewModel]
    let theme: WMFTheme
    let onTap: (WMFInterestArticleCardViewModel) -> Void

    private var columns: (left: [WMFInterestArticleCardViewModel], right: [WMFInterestArticleCardViewModel]) {
        var left: [WMFInterestArticleCardViewModel] = []
        var right: [WMFInterestArticleCardViewModel] = []
        var leftHeight: CGFloat = 0
        var rightHeight: CGFloat = 0

        for vm in viewModels {
            if leftHeight <= rightHeight {
                left.append(vm)
                leftHeight += estimatedHeight(for: vm)
            } else {
                right.append(vm)
                rightHeight += estimatedHeight(for: vm)
            }
        }
        return (left, right)
    }

    private func estimatedHeight(for vm: WMFInterestArticleCardViewModel) -> CGFloat {
        let imageHeight: CGFloat = vm.thumbnailURL != nil ? 100 : 0
        let titleLines = max(1, Int(ceil(Double(vm.title.count) / 18.0)))
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
        let cols = columns
        HStack(alignment: .top, spacing: 12) {
            column(cols.left)
            column(cols.right)
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

    @ObservedObject var viewModel: WMFInterestArticleCardViewModel
    let theme: WMFTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let uiImage = viewModel.uiImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100)
                        .clipped()
                        .contentShape(Rectangle())

                    if viewModel.isSelected, let checkmark = WMFSFSymbolIcon.for(symbol: .checkmarkCircleFill) {
                        Image(uiImage: checkmark)
                            .foregroundStyle(Color(uiColor: theme.link))
                            .background(Color(uiColor: theme.paperBackground).clipShape(Circle()))
                            .padding(6)
                    }
                }
            } else if viewModel.isSelected, let checkmark = WMFSFSymbolIcon.for(symbol: .checkmarkCircleFill) {
                HStack {
                    Spacer()
                    Image(uiImage: checkmark)
                        .foregroundStyle(Color(uiColor: theme.link))
                        .padding(6)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                WMFHtmlText(html: viewModel.title, styles: HtmlUtils.Styles(font: WMFFont.for(.subheadline), boldFont: WMFFont.for(.boldSubheadline), italicsFont: WMFFont.for(.italicSubheadline), boldItalicsFont: WMFFont.for(.italicSubheadline), color: theme.text, linkColor: theme.link, lineSpacing: 1))
                if let description = viewModel.description {
                    Text(description)
                        .font(Font(WMFFont.for(.caption1)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: theme.paperBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    viewModel.isSelected ? Color(uiColor: theme.link) : Color(uiColor: theme.border),
                    lineWidth: viewModel.isSelected ? 2 : 0.5
                )
        )
        .onAppear {
            viewModel.loadIfNeeded()
        }
    }
}
