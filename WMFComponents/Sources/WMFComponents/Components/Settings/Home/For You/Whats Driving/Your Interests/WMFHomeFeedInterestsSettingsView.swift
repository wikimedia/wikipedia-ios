import SwiftUI

public struct WMFHomeFeedInterestsSettingsView: View {

    @ObservedObject var viewModel: WMFHomeFeedInterestsSettingsViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @FocusState private var searchIsFocused: Bool

    private let bottomContentInset: CGFloat

    var theme: WMFTheme { appEnvironment.theme }

    // This screen caps Dynamic Type at accessibility2 (larger sizes mangle the grid/chips).
    // The cap modifier below only affects children, so this view's own fonts resolve against
    // the min'd value; child structs read the capped environment directly.
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize

    private var dynamicTypeSize: DynamicTypeSize {
        min(systemDynamicTypeSize, .accessibility2)
    }

    public init(viewModel: WMFHomeFeedInterestsSettingsViewModel, bottomContentInset: CGFloat = 0) {
        self.viewModel = viewModel
        self.bottomContentInset = bottomContentInset
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                if viewModel.isSearchActive {
                    languageBar
                    searchResults
                } else {
                    topicChips

                    if viewModel.isFetchingArticles {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else if !viewModel.gridViewModels.isEmpty {
                        WMFInterestArticleGridView(
                            viewModels: viewModel.gridViewModels,
                            theme: theme,
                            onTap: { vm in
                                viewModel.toggleArticleSelection(vm)
                            }
                        )
                    } else {
                        HStack {
                            Spacer()
                            Text(viewModel.emptyMessage)
                                .font(Font(WMFFont.for(.headline, sized: dynamicTypeSize)))
                                .foregroundStyle(Color(uiColor: theme.secondaryText))
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding(.top, 80)
                    }
                }
            }
            .padding(.bottom, bottomContentInset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: theme.paperBackground))
        .environment(\.colorScheme, theme.preferredColorScheme)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        if viewModel.selectedCount == 0 {
            Text(viewModel.headerTitle)
                .font(Font(WMFFont.for(.boldTitle3, sized: dynamicTypeSize)))
                .foregroundStyle(Color(uiColor: theme.text))
        } else if dynamicTypeSize.isAccessibilitySize {
            // Side-by-side would squeeze both labels into word-breaking columns at
            // accessibility sizes — stack them instead.
            VStack(alignment: .leading, spacing: 8) {
                selectedCountText
                deselectAllButton
            }
        } else {
            HStack {
                selectedCountText
                Spacer()
                deselectAllButton
            }
        }
    }

    private var selectedCountText: some View {
        Text(viewModel.selectedCountTitle)
            .font(Font(WMFFont.for(.boldTitle3, sized: dynamicTypeSize)))
            .foregroundStyle(Color(uiColor: theme.text))
    }

    private var deselectAllButton: some View {
        Button(viewModel.deselectAllTitle) {
            viewModel.deselectAll()
        }
        .font(Font(WMFFont.for(.mediumSubheadline, sized: dynamicTypeSize)))
        .foregroundStyle(Color(uiColor: theme.link))
        .accessibilityIdentifier(AccessibilityIdentifiers.Interests.deselectAllButton)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            searchBarContent
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .modifier(WMFInterestsSearchBarBackground(theme: theme))

            if searchIsFocused || viewModel.isSearchActive {
                Button(viewModel.cancelTitle) {
                    viewModel.clearSearch()
                    searchIsFocused = false
                }
                .font(Font(WMFFont.for(.body, sized: dynamicTypeSize)))
                .foregroundStyle(Color(uiColor: theme.link))
                .accessibilityIdentifier(AccessibilityIdentifiers.Interests.searchCancelButton)
            }
        }
        .animation(.default, value: searchIsFocused)
    }

    private var searchBarContent: some View {
        HStack(spacing: 6) {
            if let magnifyingGlass = WMFSFSymbolIcon.for(symbol: .magnifyingGlass, compatibleWith: dynamicTypeSize.wmfTraitCollection) {
                Image(uiImage: magnifyingGlass)
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
            }
            TextField(viewModel.searchPlaceholder, text: $viewModel.searchTerm)
                .font(Font(WMFFont.for(.body, sized: dynamicTypeSize)))
                .foregroundStyle(Color(uiColor: theme.text))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($searchIsFocused)
                .accessibilityIdentifier(AccessibilityIdentifiers.Interests.searchField)

            if viewModel.isSearchActive, let clearIcon = WMFSFSymbolIcon.for(symbol: .closeCircleFill, compatibleWith: dynamicTypeSize.wmfTraitCollection) {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(uiImage: clearIcon)
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                }
            }
        }
    }

    // Search-view-controller-style language bar: lets the user pick which of their languages to
    // search within. Only shown when there's more than one language to choose from.
    @ViewBuilder
    private var languageBar: some View {
        if viewModel.searchLanguages.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.searchLanguages, id: \.languageCode) { language in
                        LanguageChipView(
                            title: language.localizedName,
                            isSelected: language == viewModel.searchLanguage,
                            theme: theme
                        )
                        .onTapGesture {
                            viewModel.selectSearchLanguage(language)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    private var searchResults: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            if viewModel.isSearching && viewModel.searchRows.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                ForEach(viewModel.searchRows) { row in
                    WMFInterestSearchResultRow(row: row, theme: theme) {
                        if viewModel.addSearchResult(row.result) {
                            searchIsFocused = false
                        }
                    }
                    Divider()
                        .overlay(Color(uiColor: theme.border))
                        .padding(.leading, 16)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Topic chips

    private var topicChips: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.orderedTopics, id: \.self) { topic in
                        TopicChipView(
                            title: topic.displayName,
                            isSelected: viewModel.selectedTopics.contains(topic),
                            theme: theme
                        )
                        .onTapGesture {
                            let isSelecting = !viewModel.selectedTopics.contains(topic)
                            viewModel.toggleTopic(topic)
                            if isSelecting {
                                // Selection moves the chip to the front of the row, which can
                                // land off-screen — follow it after the reorder settles.
                                Task { @MainActor in
                                    withAnimation {
                                        proxy.scrollTo(topic)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .animation(.default, value: viewModel.selectedTopics)
            }
        }
    }
}

/// Capsule background for the interests search bar: liquid glass on iOS 26+,
/// a filled capsule on earlier versions.
private struct WMFInterestsSearchBarBackground: ViewModifier {
    let theme: WMFTheme

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(), in: Capsule())
        } else {
            content
                .background(
                    Capsule()
                        .fill(Color(uiColor: theme.midBackground))
                )
        }
    }
}

private struct WMFInterestSearchResultRow: View {
    // Capped by the parent screen; fonts resolve against the capped value.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize


    let row: WMFHomeFeedInterestsSettingsViewModel.SearchRow
    let theme: WMFTheme
    let onTap: () -> Void

    @ObservedObject private var card: WMFInterestArticleCardViewModel

    @ScaledMetric private var thumbnailSize: CGFloat = 44

    init(row: WMFHomeFeedInterestsSettingsViewModel.SearchRow, theme: WMFTheme, onTap: @escaping () -> Void) {
        self.row = row
        self.theme = theme
        self.onTap = onTap
        self.card = row.card
    }

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let uiImage = card.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(uiColor: theme.midBackground)
                }
            }
            .frame(width: thumbnailSize, height: thumbnailSize)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                WMFHtmlText(html: card.title, styles: HtmlUtils.Styles(font: WMFFont.for(.subheadline, sized: dynamicTypeSize), boldFont: WMFFont.for(.boldSubheadline, sized: dynamicTypeSize), italicsFont: WMFFont.for(.italicSubheadline, sized: dynamicTypeSize), boldItalicsFont: WMFFont.for(.italicSubheadline, sized: dynamicTypeSize), color: theme.text, linkColor: theme.link, lineSpacing: 1))
                if let description = card.description {
                    Text(description)
                        .font(Font(WMFFont.for(.caption1, sized: dynamicTypeSize)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                        .lineLimit(2)
                }
            }

            Spacer()

            if let icon = WMFSFSymbolIcon.for(symbol: card.isSelected ? .checkmarkCircleFill : .plusCircle, compatibleWith: dynamicTypeSize.wmfTraitCollection) {
                Image(uiImage: icon)
                    .foregroundStyle(Color(uiColor: theme.link))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onAppear {
            card.loadIfNeeded()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(card.isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier(AccessibilityIdentifiers.Interests.searchResultRow)
    }

    private var accessibilityLabel: String {
        [card.title.wmf_strippingHTMLForAccessibility, card.description]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

private struct TopicChipView: View {
    // Capped by the parent screen; fonts resolve against the capped value.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let isSelected: Bool
    let theme: WMFTheme

    private var foregroundColor: Color {
        isSelected ? Color(uiColor: theme.paperBackground) : Color(uiColor: theme.text)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            if let icon = WMFSFSymbolIcon.for(symbol: isSelected ? .checkmark : .add, font: .subheadline, compatibleWith: dynamicTypeSize.wmfTraitCollection) {
                Image(uiImage: icon)
                    .foregroundStyle(foregroundColor)
            }
            Text(title)
                .font(Font(WMFFont.for(.subheadline, sized: dynamicTypeSize)))
                .foregroundStyle(foregroundColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(isSelected ? Color(uiColor: theme.link) : Color(uiColor: theme.baseBackground))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// A search-language chip: mimics the topic chip capsule style but carries no selection icon.
private struct LanguageChipView: View {
    // Capped by the parent screen; fonts resolve against the capped value.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let isSelected: Bool
    let theme: WMFTheme

    var body: some View {
        Text(title)
            .font(Font(WMFFont.for(.subheadline, sized: dynamicTypeSize)))
            .foregroundStyle(isSelected ? Color(uiColor: theme.paperBackground) : Color(uiColor: theme.text))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? Color(uiColor: theme.link) : Color(uiColor: theme.baseBackground))
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

extension String {
    /// Strips simple HTML tags so display titles (which may contain markup) read cleanly in VoiceOver.
    var wmf_strippingHTMLForAccessibility: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
