import SwiftUI

public struct WMFRecentlySearchedView: View {

    @ObservedObject var viewModel: WMFRecentlySearchedViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    @State private var estimatedListHeight: CGFloat = 0

    @Environment(\.sizeCategory) private var sizeCategory

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(viewModel: WMFRecentlySearchedViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.recentSearchTerms.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(viewModel.localizedStrings.title)
                            .font(Font(WMFFont.for(.semiboldSubheadline)))
                            .foregroundStyle(Color(uiColor: theme.secondaryText))
                        Text(viewModel.localizedStrings.noSearches)
                            .font(Font(WMFFont.for(.callout)))
                            .foregroundStyle(Color(uiColor: theme.secondaryText))
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)

                } else {
                    HStack {
                        Text(viewModel.localizedStrings.title)
                            .font(Font(WMFFont.for(.semiboldSubheadline)))
                            .foregroundStyle(Color(uiColor: theme.secondaryText))
                        Spacer()
                        Button(viewModel.localizedStrings.clearAll) {
                            viewModel.deleteAllAction()
                        }
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundStyle(Color(uiColor: theme.link))
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                List {
                    ForEach(Array(viewModel.displayedSearchTerms.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            Text(item.text)
                                .font(Font(WMFFont.for(.body)))
                                .foregroundStyle(Color(uiColor: theme.text))
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .background(Color(theme.paperBackground))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectAction(item)
                        }
                        .swipeActions {
                            Button {
                                viewModel.deleteItemAction(index)
                            } label: {
                                Image(uiImage: WMFSFSymbolIcon.for(symbol: .trash) ?? UIImage())
                                    .accessibilityLabel(viewModel.localizedStrings.deleteActionAccessibilityLabel)
                            }
                            .tint(Color(theme.destructive))
                            .labelStyle(.iconOnly)
                        }
                        .listRowBackground(Color(theme.paperBackground))
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .frame(height: estimatedListHeight)
                if viewModel.needsAttachedView {
                    let assignment = try? viewModel.tabsDataController.getMoreDynamicTabsExperimentAssignment()
                    if viewModel.devSettingsDataControler.enableMoreDynamicTabsBYR ||
                       (!viewModel.devSettingsDataControler.enableMoreDynamicTabsDYK && assignment == .becauseYouRead),
                       let becauseVM = viewModel.becauseYouReadViewModel {
                        WMFBecauseYouReadView(viewModel: becauseVM)
                    } else if viewModel.devSettingsDataControler.enableMoreDynamicTabsBYR || (viewModel.devSettingsDataControler.enableMoreDynamicTabsDYK || assignment == .didYouKnow) {
                        Text("Did you know")
                    }
                }
            }
        }
        .background(Color(theme.paperBackground))
        .padding(.top, viewModel.topPadding)
        .onAppear {
            recalculateEstimatedListHeight()
        }
        .onChange(of: sizeCategory) { _ in
            recalculateEstimatedListHeight()
        }
    }

    private func recalculateEstimatedListHeight() {
        let screenWidth = UIScreen.main.bounds.width
        let horizontalPadding: CGFloat = 32
        let availableWidth = screenWidth - horizontalPadding
        let font = UIFont.preferredFont(forTextStyle: .body)

        let verticalPadding: CGFloat = 16
        let rowSpacing: CGFloat = 8

        let extraPaddingPerRow: CGFloat = sizeCategory.isAccessibilityCategory ? 6 : 0

        let rowHeights: [CGFloat] = viewModel.displayedSearchTerms.map { item in
            let textHeight = estimatedTextHeight(
                text: item.text,
                font: font,
                width: availableWidth
            )
            return textHeight + verticalPadding + extraPaddingPerRow
        }
        let totalRowSpacing = CGFloat(max(viewModel.displayedSearchTerms.count - 1, 0)) * rowSpacing
        let totalHeight = rowHeights.reduce(0, +) + totalRowSpacing

        estimatedListHeight = totalHeight
    }
}

import UIKit

func estimatedTextHeight(text: String, font: UIFont, width: CGFloat) -> CGFloat {
    let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
    let boundingBox = text.boundingRect(
        with: constraintRect,
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: font],
        context: nil
    )
    return ceil(boundingBox.height)
}

