import SwiftUI
import WMFData
import WMFNativeLocalizations

// MARK: - Community Feed View

/// The Home tab's Community feed: a disclaimer, then one block per day, newest first, each with its
/// date and the day's modules. The footer loads the day before the oldest one shown.
///
/// The feed is laid out in the direction of its wiki's language, and its headers are in that
/// language, so an Arabic feed reads right to left in an English app. The Home header around it
/// stays in the app language.
struct WMFCommunityFeedView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var theme: WMFTheme { appEnvironment.theme }

    let pages: [WMFHomeCommunityViewModel]
    let moduleVisibility: WMFCommunityModuleVisibility
    let hiddenCardKeys: Set<String>
    let isLoadingPreviousPage: Bool
    let previousPageFailed: Bool
    let previousPageErrorTitle: String
    let retryTitle: String
    let onHideModule: (WMFCommunityModule) -> Void
    let onHideCard: (String) -> Void
    /// Opens the Community feed settings from a module's menu. Nil hides the menu item.
    let onCustomize: (() -> Void)?
    let onRefresh: () async -> Void
    let onTapSeePastContent: () -> Void
    let onArticleAction: (WMFCommunityArticleAction, String, WMFProject, WMFCommunityModule) -> Void
    let isArticleSaved: (String, WMFProject) -> Bool
    let onTapNewsStory: (WMFFeedNewsItem, WMFProject) -> Void
    let onTapPictureOfTheDay: (Date) -> Void
    let onTapMoreTopRead: (WMFHomeCommunityViewModel) -> Void
    /// Opens the day's On this day list, scrolled to the event when one is given.
    let onTapOnThisDay: (WMFHomeCommunityViewModel, WMFHomeCommunityViewModel.OnThisDayItem?) -> Void

    var scrollToTopRequestID: Int = 0

    /// Space at the top for the Home header that floats over the feed. The feed scrolls under the
    /// header, so this is a content margin and not a frame inset.
    var topContentInset: CGFloat = 0

    private static let topAnchorID = "community-feed-top"
    private static let horizontalPadding = WMFCommunityFeedMetrics.horizontalPadding

    /// Every page of one feed comes from the same wiki, so the first page speaks for all of them.
    private var strings: WMFCommunityFeedStrings {
        pages.first?.strings ?? WMFCommunityFeedStrings(languageCode: nil)
    }

    private var layoutDirection: LayoutDirection {
        (pages.first?.isRTL ?? false) ? .rightToLeft : .leftToRight
    }

    private var usesTwoColumns: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // The anchor sits above the top padding, so a scroll to the top lands where the
                    // feed first opens.
                    Color.clear
                        .frame(height: 0)
                        .id(Self.topAnchorID)
                    LazyVStack(alignment: .leading, spacing: WMFCommunityFeedMetrics.moduleSpacing) {
                        // On iPad the disclaimer is drawn inside the first day's leading column, so
                        // the trailing column starts at the top beside it, as in the Figma.
                        if !usesTwoColumns || firstVisiblePageID == nil {
                            disclaimer
                        }
                        ForEach(pages) { page in
                            // A day whose modules are all off, hidden or missing would be a bare date.
                            let modules = page.visibleModules(visibility: moduleVisibility, hiddenCardKeys: hiddenCardKeys)
                            if !modules.isEmpty {
                                daySection(page, modules: modules, isFirstDay: page.id == firstVisiblePageID, isLastDay: page.id == lastVisiblePageID)
                            }
                        }
                        // On iPad the footer goes under the trailing column of the last day, as in
                        // the Figma. It is drawn here only when no day can hold it.
                        if !usesTwoColumns || lastVisiblePageID == nil {
                            footer
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                // Without a fixed width, a child that reports a wider ideal size widens the whole
                // stack, and every module runs past the trailing edge of the screen.
                .containerRelativeFrame(.horizontal)
            }
            .contentMargins(.top, topContentInset, for: .scrollContent)
            .contentMargins(.top, topContentInset, for: .scrollIndicators)
            .refreshable {
                await onRefresh()
            }
            .onChange(of: scrollToTopRequestID) { _, _ in
                withAnimation {
                    proxy.scrollTo(Self.topAnchorID, anchor: .top)
                }
            }
        }
        .background(Color(uiColor: theme.paperBackground))
        .environment(\.layoutDirection, layoutDirection)
    }

    // MARK: - Disclaimer

    private var disclaimer: some View {
        HStack(spacing: 12) {
            Text(strings.disclaimer)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Image(uiImage: WMFIcon.wikipediaGlobe ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(width: WMFCommunityFeedMetrics.disclaimerGlobeSize, height: WMFCommunityFeedMetrics.disclaimerGlobeSize)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .padding(.leading, 20)
        .padding(.trailing, 12)
        // A full pill, as in the Figma. A tall disclaimer (large text) keeps a rounded rectangle.
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color(uiColor: theme.midBackground))
        )
        .padding(.horizontal, Self.horizontalPadding)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Day

    /// The first day that shows any module. On iPad it holds the disclaimer.
    private var firstVisiblePageID: String? {
        pages.first { !$0.visibleModules(visibility: moduleVisibility, hiddenCardKeys: hiddenCardKeys).isEmpty }?.id
    }

    /// The last day that shows any module. On iPad it holds the footer.
    private var lastVisiblePageID: String? {
        pages.last { !$0.visibleModules(visibility: moduleVisibility, hiddenCardKeys: hiddenCardKeys).isEmpty }?.id
    }

    @ViewBuilder
    private func daySection(_ page: WMFHomeCommunityViewModel, modules: [WMFCommunityModule], isFirstDay: Bool, isLastDay: Bool) -> some View {
        if usesTwoColumns {
            // The date heads the leading column, so the trailing column starts level with it, and
            // on the first day level with the disclaimer. VoiceOver reads the leading column, then
            // the trailing one. Each module pads itself, so the columns sit edge to edge and their
            // text lines up with the date.
            let columns = WMFHomeCommunityViewModel.columns(for: modules)
            VStack(alignment: .leading, spacing: WMFCommunityFeedMetrics.moduleSpacing) {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: WMFCommunityFeedMetrics.dateToModuleSpacing) {
                        if isFirstDay {
                            disclaimer
                                .padding(.bottom, 8)
                        }
                        dateHeader(page)
                        moduleColumn(columns.leading, page: page)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    moduleColumn(columns.trailing, page: page)
                }
                // The footer sits under the trailing column, as in the Figma, but below the end of both
                // columns, so it never floats beside a longer leading column.
                if isLastDay {
                    HStack(spacing: 0) {
                        Color.clear
                            .frame(maxWidth: .infinity, maxHeight: 0)
                            .accessibilityHidden(true)
                        footer
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: WMFCommunityFeedMetrics.dateToModuleSpacing) {
                dateHeader(page)
                moduleColumn(modules, page: page)
            }
        }
    }

    private func dateHeader(_ page: WMFHomeCommunityViewModel) -> some View {
        Text(page.date)
            .font(Font(WMFFont.for(.subheadline)))
            .foregroundStyle(Color(uiColor: theme.secondaryText))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Self.horizontalPadding)
            .accessibilityAddTraits(.isHeader)
    }

    private func moduleColumn(_ modules: [WMFCommunityModule], page: WMFHomeCommunityViewModel) -> some View {
        VStack(alignment: .leading, spacing: WMFCommunityFeedMetrics.moduleSpacing) {
            ForEach(modules, id: \.self) { module in
                moduleView(module, page: page)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func moduleView(_ module: WMFCommunityModule, page: WMFHomeCommunityViewModel) -> some View {
        VStack(alignment: .leading, spacing: WMFCommunityFeedMetrics.headerToContentSpacing) {
            moduleHeader(module, page: page)
            moduleContent(module, page: page)
        }
    }

    // MARK: - Module content
    // Each module's own design is its own task. These keep the content and the interactions of the
    // Explore feed's cards.

    @ViewBuilder
    private func moduleContent(_ module: WMFCommunityModule, page: WMFHomeCommunityViewModel) -> some View {
        switch module {
        case .featuredArticle:
            if let article = page.featuredArticle, let item = page.featuredArticleItem {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        onArticleAction(.open, item.title, page.project, .featuredArticle)
                    } label: {
                        WMFFeaturedArticleCard(article: article, theme: theme)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .articleContextMenu(item, page: page, module: .featuredArticle, isSaved: isArticleSaved(item.title, page.project), onAction: onArticleAction)
                    saveButton(item, page: page, module: .featuredArticle)
                }
                .padding(.horizontal, Self.horizontalPadding)
            }
        case .topRead:
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(page.topReadItems.enumerated()), id: \.offset) { _, item in
                    articleRow(item, page: page, module: .topRead)
                }
                moreLink(strings.moreTopRead) {
                    onTapMoreTopRead(page)
                }
            }
            .padding(.horizontal, Self.horizontalPadding)
        case .inTheNews:
            // The story card brings its own horizontal padding.
            TabView {
                ForEach(Array(page.newsItems.enumerated()), id: \.offset) { _, item in
                    Button {
                        onTapNewsStory(item.newsItem, page.project)
                    } label: {
                        WMFNewsStoryCard(story: item.story, imageURLString: item.imageURLString, theme: theme)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(maxWidth: .infinity)
            .frame(height: WMFCommunityFeedMetrics.newsCardHeight)
        case .onThisDay:
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array((page.onThisDayItems ?? []).enumerated()), id: \.offset) { _, item in
                    onThisDayEvent(item, page: page)
                }
                moreLink(strings.moreOnThisDay) {
                    onTapOnThisDay(page, nil)
                }
            }
            .padding(.horizontal, Self.horizontalPadding)
        case .pictureOfDay:
            if let pictureOfDay = page.pictureOfDay {
                // Edge to edge on a phone. In an iPad column it is inset like the other modules.
                Button {
                    onTapPictureOfTheDay(page.feedDate)
                } label: {
                    WMFPictureOfTheDayCard(imageSource: pictureOfDay, caption: page.pictureOfDayCaption, theme: theme)
                        .clipShape(RoundedRectangle(cornerRadius: usesTwoColumns ? 8 : 0))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(page.pictureOfDayCaption ?? module.title(languageCode: page.strings.languageCode))
                .accessibilityHint(WMFCommunityFeedStrings.pictureOfTheDayHint)
                .padding(.horizontal, usesTwoColumns ? Self.horizontalPadding : 0)
            }
        }
    }

    private func onThisDayEvent(_ item: WMFHomeCommunityViewModel.OnThisDayItem, page: WMFHomeCommunityViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Like the Explore card, a tap on the event opens the day's list at that event.
            Button {
                onTapOnThisDay(page, item)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: String(item.year))
                        .font(Font(WMFFont.for(.boldTitle3)))
                        .foregroundStyle(Color(uiColor: theme.text))
                    Text(item.yearsAgo)
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                    Text(item.text)
                        .font(Font(WMFFont.for(.callout)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            if !item.pages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Array(item.pages.enumerated()), id: \.offset) { _, article in
                            articleRow(article, page: page, module: .onThisDay)
                                .containerRelativeFrame(.horizontal) { width, _ in width * 0.8 }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Article rows and actions

    /// A row for one article: its title (italics kept), description and thumbnail, all from the
    /// feed response. A tap opens the article; a long press shows the Explore card's menu.
    private func articleRow(_ article: WMFCommunityArticle, page: WMFHomeCommunityViewModel, module: WMFCommunityModule) -> some View {
        Button {
            onArticleAction(.open, article.title, page.project, module)
        } label: {
            WMFCommunityArticleRow(article: article, theme: theme)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .articleContextMenu(article, page: page, module: module, isSaved: isArticleSaved(article.title, page.project), onAction: onArticleAction)
    }

    /// "Save for later" under the featured article, as on the Explore card. It turns into "Saved
    /// for later" once saved, and a second tap unsaves.
    private func saveButton(_ article: WMFCommunityArticle, page: WMFHomeCommunityViewModel, module: WMFCommunityModule) -> some View {
        let isSaved = isArticleSaved(article.title, page.project)
        return Button {
            onArticleAction(isSaved ? .unsave : .save, article.title, page.project, module)
        } label: {
            HStack(spacing: 6) {
                Image(uiImage: WMFSFSymbolIcon.for(symbol: isSaved ? .bookmarkFill : .bookmark, font: .subheadline) ?? UIImage())
                    .renderingMode(.template)
                    .accessibilityHidden(true)
                Text(isSaved ? CommonStrings.savedTitle(languageCode: page.strings.languageCode) : CommonStrings.saveTitle(languageCode: page.strings.languageCode))
                    .font(Font(WMFFont.for(.subheadline)))
            }
            .foregroundStyle(Color(uiColor: theme.link))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSaved ? CommonStrings.accessibilitySavedTitle : CommonStrings.saveTitle(languageCode: page.strings.languageCode))
    }

    /// A trailing link with a chevron under a module, such as "More top read".
    private func moreLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .chevronForward, font: .semiboldSubheadline) ?? UIImage())
                    .renderingMode(.template)
                    .flipsForRightToLeftLayoutDirection(true)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Color(uiColor: theme.link))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Module header

    private func moduleHeader(_ module: WMFCommunityModule, page: WMFHomeCommunityViewModel) -> some View {
        let hideKey = page.hideKey(for: module)
        // The title and the "…" button share a row, so the button centers on the title, as in the
        // Figma. The subtitle runs below under the full width.
        return VStack(alignment: .leading, spacing: WMFCommunityFeedMetrics.titleToSubtitleSpacing) {
            Text(module.title(languageCode: page.strings.languageCode))
                .font(Font(WMFFont.for(.boldTitle3)))
                .foregroundStyle(Color(uiColor: theme.text))
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                // Room for the button, which is an overlay so that its 44 pt touch target does
                // not make the title row taller and push the subtitle down.
                .padding(.trailing, 44)
                .overlay(alignment: .trailing) {
                    moduleMenu(module, hideKey: hideKey)
                }
            Text(page.subtitle(for: module))
                .font(Font(WMFFont.for(.callout)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Self.horizontalPadding)
    }

    /// The Explore card's menu: hide this card, hide every card of the module, and customize the
    /// feed. The menu's own design has its own task.
    private func moduleMenu(_ module: WMFCommunityModule, hideKey: String?) -> some View {
        Menu {
            Button(role: .destructive) {
                if let hideKey { onHideCard(hideKey) }
            } label: {
                Label {
                    Text(WMFHomeLocalizedStrings.hideCard)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .eyeSlash) ?? UIImage())
                }
            }
            .disabled(hideKey == nil)
            Button(role: .destructive) {
                onHideModule(module)
            } label: {
                Label {
                    Text(WMFHomeLocalizedStrings.hideModule)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .xmarkCircle) ?? UIImage())
                }
            }
            if let onCustomize {
                Divider()
                Button(action: onCustomize) {
                    Label {
                        Text(CommonStrings.customizeCommunityFeedTitle)
                    } icon: {
                        Image(uiImage: WMFSFSymbolIcon.for(symbol: .gear) ?? UIImage())
                    }
                }
            }
        } label: {
            Image(uiImage: WMFSFSymbolIcon.for(symbol: .ellipsis) ?? UIImage())
                .foregroundStyle(Color(uiColor: theme.secondaryText))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(WMFHomeLocalizedStrings.moreOptions)
    }

    // MARK: - Footer

    private var footer: some View {
        Group {
            if isLoadingPreviousPage {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else if previousPageFailed {
                VStack(spacing: 8) {
                    Text(previousPageErrorTitle)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                        .multilineTextAlignment(.center)
                    Button(action: onTapSeePastContent) {
                        Text(retryTitle)
                            .font(Font(WMFFont.for(.semiboldSubheadline)))
                            .foregroundStyle(Color(uiColor: theme.link))
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                Button(action: onTapSeePastContent) {
                    HStack(spacing: 6) {
                        Image(uiImage: WMFSFSymbolIcon.for(symbol: .calendar, font: .semiboldSubheadline) ?? UIImage())
                            .renderingMode(.template)
                            .accessibilityHidden(true)
                        Text(strings.seePastContent)
                            .font(Font(WMFFont.for(.semiboldSubheadline)))
                    }
                    .foregroundStyle(Color(uiColor: theme.paperBackground))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color(uiColor: theme.link)))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Self.horizontalPadding)
    }
}

// MARK: - Long-press menu

private extension View {
    /// The Explore feed's long-press menu for an article: open, open in a new or a background tab,
    /// save or unsave, and share, over a preview of the article.
    func articleContextMenu(_ article: WMFCommunityArticle, page: WMFHomeCommunityViewModel, module: WMFCommunityModule, isSaved: Bool, onAction: @escaping (WMFCommunityArticleAction, String, WMFProject, WMFCommunityModule) -> Void) -> some View {
        contextMenu {
            Button {
                onAction(.open, article.title, page.project, module)
            } label: {
                Label {
                    Text(CommonStrings.articleTabsOpen)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .chevronForward) ?? UIImage())
                }
            }
            Button {
                onAction(.openInNewTab, article.title, page.project, module)
            } label: {
                Label {
                    Text(CommonStrings.articleTabsOpenInNewTab)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .tabsIcon) ?? UIImage())
                }
            }
            Button {
                onAction(.openInBackgroundTab, article.title, page.project, module)
            } label: {
                Label {
                    Text(CommonStrings.articleTabsOpenInBackgroundTab)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .tabsIconBackground) ?? UIImage())
                }
            }
            Button {
                onAction(isSaved ? .unsave : .save, article.title, page.project, module)
            } label: {
                Label {
                    Text(isSaved ? CommonStrings.unsaveTitle : CommonStrings.saveTitle)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: isSaved ? .bookmarkFill : .bookmark) ?? UIImage())
                }
            }
            Button {
                onAction(.share, article.title, page.project, module)
            } label: {
                Label {
                    Text(CommonStrings.shortShareTitle)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .share) ?? UIImage())
                }
            }
        } preview: {
            WMFArticlePreviewView(viewModel: WMFArticlePreviewViewModel(
                url: nil,
                titleHtml: article.plainTitle,
                description: article.description,
                imageURL: article.thumbnailURL,
                isSaved: isSaved,
                snippet: article.extract
            ))
        }
    }
}

// MARK: - Article Row

/// One article in Top read or under an On this day event. It shows the feed's display title with
/// its italics, the description and the thumbnail, without a request of its own.
private struct WMFCommunityArticleRow: View {

    let article: WMFCommunityArticle
    let theme: WMFTheme

    @StateObject private var imageViewModel = WMFCommunityThumbnailViewModel()

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                WMFHtmlText(
                    html: article.displayTitleHTML,
                    styles: HtmlUtils.Styles(
                        font: WMFFont.for(.callout),
                        boldFont: WMFFont.for(.boldCallout),
                        italicsFont: WMFFont.for(.italicCallout),
                        boldItalicsFont: WMFFont.for(.boldItalicCallout),
                        color: theme.text,
                        linkColor: theme.text,
                        lineSpacing: 0
                    ),
                    lineLimit: 1
                )
                if let description = article.description, !description.isEmpty {
                    Text(description)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                if let uiImage = imageViewModel.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.clear
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .accessibilityHidden(true)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([article.plainTitle, article.description].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
        .onAppear {
            if let url = article.thumbnailURL {
                imageViewModel.load(url: url)
            }
        }
    }
}

@MainActor
private final class WMFCommunityThumbnailViewModel: ObservableObject {
    @Published var uiImage: UIImage?
    private var loadTask: Task<Void, Never>?

    func load(url: URL) {
        guard uiImage == nil, loadTask == nil else { return }
        loadTask = Task { [weak self] in
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: url) else { return }
            self?.uiImage = UIImage(data: data)
        }
    }

    deinit {
        loadTask?.cancel()
    }
}

// MARK: - Featured Article Card

private struct WMFFeaturedArticleCard: View {

    let article: WMFFeedArticle
    let theme: WMFTheme

    @StateObject private var imageViewModel = WMFFeaturedArticleImageViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let uiImage = imageViewModel.uiImage {
                // The image fills a box of the card's width. Sized by the image itself, a wide
                // aspect fill reports its full width and pushes the whole card off screen.
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: WMFCommunityFeedMetrics.featuredArticleImageHeight)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
            }
            WMFHtmlText(
                html: article.displayTitle ?? article.title ?? "",
                styles: HtmlUtils.Styles(
                    font: WMFFont.for(.boldTitle3),
                    boldFont: WMFFont.for(.boldTitle3),
                    italicsFont: WMFFont.for(.italicGeorgiaTitle3),
                    boldItalicsFont: WMFFont.for(.italicGeorgiaTitle3),
                    color: theme.text,
                    linkColor: theme.link,
                    lineSpacing: 0
                )
            )
            if let description = article.description {
                Text(description)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
            }
            if let extract = article.extract {
                Text(extract)
                    .font(Font(WMFFont.for(.callout)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .lineLimit(4)
            }
        }
        .onAppear {
            if let urlString = article.thumbnail?.source ?? article.originalImage?.source,
               let url = URL(string: urlString) {
                imageViewModel.load(url: url)
            }
        }
    }
}

@MainActor
private final class WMFFeaturedArticleImageViewModel: ObservableObject {
    @Published var uiImage: UIImage?

    func load(url: URL) {
        Task {
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: url) else { return }
            self.uiImage = UIImage(data: data)
        }
    }
}

// MARK: - News Story Card

private struct WMFNewsStoryCard: View {

    let story: String
    let imageURLString: String?
    let theme: WMFTheme

    @StateObject private var imageViewModel = WMFNewsStoryImageViewModel()

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ScrollView {
                Text(story)
                    .font(Font(WMFFont.for(.callout)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .multilineTextAlignment(.leading)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let uiImage = imageViewModel.uiImage {
                // Fixed width so the story keeps the majority of the card
                Color.clear
                    .frame(width: 120)
                    .overlay(
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    )
                    .clipped()
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: theme.midBackground))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onAppear {
            if let imageURLString, let url = URL(string: imageURLString) {
                imageViewModel.load(url: url)
            }
        }
    }
}

@MainActor
private final class WMFNewsStoryImageViewModel: ObservableObject {
    @Published var uiImage: UIImage?
    private var loadTask: Task<Void, Never>?

    func load(url: URL) {
        loadTask?.cancel()
        loadTask = Task {
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: url) else { return }
            self.uiImage = UIImage(data: data)
        }
    }

    deinit {
        loadTask?.cancel()
    }
}

// MARK: - Picture of the Day Card

private struct WMFPictureOfTheDayCard: View {

    let imageSource: WMFFeedImageSource
    /// The picture's description, drawn over the bottom of the image as on the Explore card.
    let caption: String?
    let theme: WMFTheme

    @StateObject private var imageViewModel = WMFPictureOfTheDayImageViewModel()

    var body: some View {
        image
            .overlay(alignment: .bottomLeading) {
                if let caption, imageViewModel.uiImage != nil {
                    Text(caption)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundStyle(Color.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // White text needs a dark base over any picture.
                        .background(
                            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                        )
                        .accessibilityHidden(true)
                }
            }
    }

    private var image: some View {
        Group {
            if let uiImage = imageViewModel.uiImage {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: WMFCommunityFeedMetrics.pictureOfTheDayHeight)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            } else {
                Color(uiColor: theme.midBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: WMFCommunityFeedMetrics.pictureOfTheDayHeight)
            }
        }
        .onAppear {
            if let urlString = imageSource.source, let url = URL(string: urlString) {
                imageViewModel.load(url: url)
            }
        }
    }
}

@MainActor
private final class WMFPictureOfTheDayImageViewModel: ObservableObject {
    @Published var uiImage: UIImage?

    func load(url: URL) {
        Task {
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: url) else { return }
            self.uiImage = UIImage(data: data)
        }
    }
}

// MARK: - Metrics

/// The Community feed's layout numbers, from the Figma.
enum WMFCommunityFeedMetrics {
    static let horizontalPadding: CGFloat = 16

    /// Between two modules in a column, and between a day's last module and the next date.
    static let moduleSpacing: CGFloat = 34
    /// Between a module's subtitle and its content.
    static let headerToContentSpacing: CGFloat = 18
    /// Between a module's title and its subtitle.
    static let titleToSubtitleSpacing: CGFloat = 8
    /// Between the date and the day's first module.
    static let dateToModuleSpacing: CGFloat = 16

    static let disclaimerGlobeSize: CGFloat = 44

    static let featuredArticleImageHeight: CGFloat = 200
    static let newsCardHeight: CGFloat = 200
    static let pictureOfTheDayHeight: CGFloat = 300
}
