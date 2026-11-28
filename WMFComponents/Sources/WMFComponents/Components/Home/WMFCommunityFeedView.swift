import SwiftUI
import WMFData
import WMFNativeLocalizations

// MARK: - Community Feed View

/// The Home tab's Community feed: a disclaimer, then one block per day, newest first, each with its
/// date and the day's modules. The footer loads the day before the oldest one shown.
///
/// The feed is laid out in the direction of its wiki's language, and its headers are in that
/// language, so an Arabic feed reads right to left in an English app. The date above each day and
/// the article menus stay in the app language. The Home header's segment titles follow the wiki
/// language (see `WMFHomeViewModel.feedLanguageCode`).
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
    /// Set when today could not load and an earlier stored day is on screen. A note with a retry
    /// then shows above the feed.
    let todayErrorTitle: String?
    let retryTitle: String
    let onHideModule: (WMFCommunityModule) -> Void
    let onHideCard: (String) -> Void
    /// Opens the Community feed settings from a module's menu. Nil hides the menu item.
    let onCustomize: (() -> Void)?
    let onRefresh: () async -> Void
    let onTapSeePastContent: () -> Void
    let isRetryingToday: Bool
    let onRetryToday: () -> Void
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
        (pages.first?.project.isRTL ?? false) ? .rightToLeft : .leftToRight
    }

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    /// True when a day is drawn in two columns: a regular-width screen and more than one module.
    /// A day of one module is drawn at full width, like on a phone.
    private func usesTwoColumns(_ modules: [WMFCommunityModule]) -> Bool {
        isRegularWidth && modules.count > 1
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
                        if let todayErrorTitle {
                            todayErrorNote(todayErrorTitle)
                        }
                        // On iPad the disclaimer is drawn inside the first day's leading column, so
                        // the trailing column starts at the top beside it, as in the Figma. A first
                        // day drawn at full width has no leading column, so it goes above it.
                        if !usesTwoColumns(firstVisiblePage.map { visibleModules($0) } ?? []) {
                            disclaimer
                        }
                        ForEach(pages) { page in
                            // A day whose modules are all off, hidden or missing would be a bare date.
                            let modules = page.visibleModules(visibility: moduleVisibility, hiddenCardKeys: hiddenCardKeys)
                            if !modules.isEmpty {
                                daySection(page, modules: modules, isFirstDay: page.id == firstVisiblePage?.id, isLastDay: page.id == lastVisiblePage?.id)
                            }
                        }
                        // The last day draws the footer right under its last module. It is drawn
                        // here only when no day shows anything.
                        if lastVisiblePage == nil {
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
            .accessibilityIdentifier(AccessibilityIdentifiers.Community.feed)
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

    // MARK: - Today error

    /// One line over a stored earlier day: today did not load. The date header below already
    /// says which day the reader sees.
    private func todayErrorNote(_ title: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            if isRetryingToday {
                ProgressView()
                    .frame(minHeight: 44)
            } else {
                Button(action: onRetryToday) {
                    Text(retryTitle)
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                        .foregroundStyle(Color(uiColor: theme.link))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityIdentifiers.Community.todayErrorRetryButton)
            }
        }
        .padding(.horizontal, Self.horizontalPadding)
    }

    // MARK: - Disclaimer

    private var disclaimer: some View {
        HStack(spacing: 10) {
            Text(strings.disclaimer)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundStyle(Color(uiColor: theme.text))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Image(uiImage: WMFIcon.wikipediaGlobe ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(width: WMFCommunityFeedMetrics.disclaimerGlobeSize, height: WMFCommunityFeedMetrics.disclaimerGlobeSize)
                .accessibilityHidden(true)
        }
        .padding(16)
        // A full pill, as in the Figma. A tall disclaimer (large text) keeps a rounded rectangle.
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color(uiColor: theme.baseBackground))
        )
        .padding(.horizontal, Self.horizontalPadding)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Day

    private func visibleModules(_ page: WMFHomeCommunityViewModel) -> [WMFCommunityModule] {
        page.visibleModules(visibility: moduleVisibility, hiddenCardKeys: hiddenCardKeys)
    }

    /// The first day that shows any module. On iPad it holds the disclaimer.
    private var firstVisiblePage: WMFHomeCommunityViewModel? {
        pages.first { !visibleModules($0).isEmpty }
    }

    /// The last day that shows any module. It holds the footer.
    private var lastVisiblePage: WMFHomeCommunityViewModel? {
        pages.last { !visibleModules($0).isEmpty }
    }

    @ViewBuilder
    private func daySection(_ page: WMFHomeCommunityViewModel, modules: [WMFCommunityModule], isFirstDay: Bool, isLastDay: Bool) -> some View {
        if usesTwoColumns(modules) {
            // The date heads the leading column, so the trailing column starts level with it, and
            // on the first day level with the disclaimer. VoiceOver reads the leading column, then
            // the trailing one. Each module pads itself, so the columns sit edge to edge and their
            // text lines up with the date.
            let columns = WMFHomeCommunityViewModel.columns(for: modules)
            // The footer goes 16 pt under the trailing column's last module.
            WMFCommunityColumnsLayout(footerSpacing: WMFCommunityFeedMetrics.footerSpacing) {
                VStack(alignment: .leading, spacing: WMFCommunityFeedMetrics.dateToModuleSpacing) {
                    if isFirstDay {
                        disclaimer
                            .padding(.bottom, 12)
                    }
                    dateHeader(page)
                    moduleColumn(columns.leading, page: page)
                }
                moduleColumn(columns.trailing, page: page)
                if isLastDay {
                    footer
                }
            }
        } else {
            VStack(alignment: .leading, spacing: WMFCommunityFeedMetrics.dateToModuleSpacing) {
                dateHeader(page)
                VStack(alignment: .leading, spacing: WMFCommunityFeedMetrics.footerSpacing) {
                    moduleColumn(modules, page: page)
                    if isLastDay {
                        footer
                    }
                }
            }
        }
    }

    private func dateHeader(_ page: WMFHomeCommunityViewModel) -> some View {
        Text(page.date)
            .font(Font(WMFFont.for(.subheadline)))
            .foregroundStyle(Color(uiColor: theme.text))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Self.horizontalPadding)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier(AccessibilityIdentifiers.Community.dateHeader)
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
                    .accessibilityIdentifier(AccessibilityIdentifiers.Community.featuredArticle)
                    .articleContextMenu(item, page: page, module: .featuredArticle, isSaved: isArticleSaved(item.title, page.project), onAction: onArticleAction)
                    saveButton(item, page: page, module: .featuredArticle)
                }
                .padding(.horizontal, Self.horizontalPadding)
            }
        case .topRead:
            VStack(alignment: .leading, spacing: 0) {
                ForEach(page.topReadItems, id: \.title) { item in
                    articleRow(item, page: page, module: .topRead)
                }
                moreLink(strings.moreTopRead, accessibilityIdentifier: AccessibilityIdentifiers.Community.moreTopReadButton) {
                    onTapMoreTopRead(page)
                }
            }
            .padding(.horizontal, Self.horizontalPadding)
        case .inTheNews:
            // The story card brings its own horizontal padding.
            let newsStoryHint = WMFCommunityFeedStrings.newsStoryHint(storyCount: page.newsItems.count)
            TabView {
                ForEach(page.newsItems, id: \.id) { item in
                    Button {
                        onTapNewsStory(item.newsItem, page.project)
                    } label: {
                        WMFNewsStoryCard(story: item.story, imageURLString: item.imageURLString, theme: theme)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(newsStoryHint)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Community.newsStory)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(maxWidth: .infinity)
            .frame(height: WMFCommunityFeedMetrics.newsCardHeight)
        case .onThisDay:
            VStack(alignment: .leading, spacing: 16) {
                ForEach(page.onThisDayItems ?? [], id: \.id) { item in
                    onThisDayEvent(item, page: page)
                }
                moreLink(strings.moreOnThisDay, accessibilityIdentifier: AccessibilityIdentifiers.Community.moreOnThisDayButton) {
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
                        .clipShape(RoundedRectangle(cornerRadius: isRegularWidth ? 8 : 0))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(page.pictureOfDayCaption ?? module.title(languageCode: page.strings.languageCode))
                .accessibilityHint(WMFCommunityFeedStrings.pictureOfTheDayHint)
                .accessibilityIdentifier(AccessibilityIdentifiers.Community.pictureOfTheDay)
                .padding(.horizontal, isRegularWidth ? Self.horizontalPadding : 0)
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
                    Text(verbatim: item.yearText)
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
            .accessibilityIdentifier(AccessibilityIdentifiers.Community.onThisDayEvent)
            if !item.pages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(item.pages, id: \.title) { article in
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
        // The button is the one VoiceOver element of the row, so VoiceOver reads the plain title
        // and the description once, with one "button" trait.
        .accessibilityLabel([article.plainTitle, article.description].compactMap { $0 }.joined(separator: ", "))
        .optionalAccessibilityIdentifier(module == .topRead ? AccessibilityIdentifiers.Community.topReadRow : nil)
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
        .accessibilityIdentifier(AccessibilityIdentifiers.Community.saveForLaterButton)
        // No separate accessibility label: the visible "Save for later" or "Saved for later" is
        // the label, so VoiceOver reads both states in the feed's language.
    }

    /// A trailing link with a chevron under a module, such as "More top read".
    private func moreLink(_ title: String, accessibilityIdentifier: String, action: @escaping () -> Void) -> some View {
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
        .accessibilityIdentifier(accessibilityIdentifier)
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
                .accessibilityIdentifier(AccessibilityIdentifiers.Community.module(module.accessibilityID))
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
            .accessibilityIdentifier(AccessibilityIdentifiers.Community.menuHideCardItem)
            Button(role: .destructive) {
                onHideModule(module)
            } label: {
                Label {
                    Text(WMFHomeLocalizedStrings.hideModule)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .xmarkCircle) ?? UIImage())
                }
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Community.menuHideModuleItem)
            if let onCustomize {
                Divider()
                Button(action: onCustomize) {
                    Label {
                        Text(CommonStrings.customizeCommunityFeedTitle)
                    } icon: {
                        Image(uiImage: WMFSFSymbolIcon.for(symbol: .gear) ?? UIImage())
                    }
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Community.menuCustomizeItem)
            }
        } label: {
            Image(uiImage: WMFSFSymbolIcon.for(symbol: .ellipsis) ?? UIImage())
                .foregroundStyle(Color(uiColor: theme.secondaryText))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(WMFHomeLocalizedStrings.moreOptions)
        .accessibilityIdentifier(AccessibilityIdentifiers.Community.moduleMenuButton(module.accessibilityID))
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
                .accessibilityIdentifier(AccessibilityIdentifiers.Community.seePastContentButton)
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

    @StateObject private var imageViewModel = WMFCommunityImageLoader()

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
        .task(id: article.thumbnailURL) {
            await imageViewModel.load(url: article.thumbnailURL)
        }
    }
}

/// Loads a card's image. Cards are reused when a refresh brings new content for the same day, so a
/// new URL clears the old image and loads again, and a stale load never lands on the new content.
@MainActor
private final class WMFCommunityImageLoader: ObservableObject {
    @Published private(set) var uiImage: UIImage?
    private var url: URL?

    func load(url: URL?) async {
        // A load cut short (the card scrolled off screen) or one that failed left no image, so the
        // same URL loads again when the card comes back.
        guard url != self.url || uiImage == nil else { return }
        self.url = url
        uiImage = nil
        guard let url,
              let data = try? await WMFImageDataController.shared.fetchImageData(url: url),
              !Task.isCancelled, url == self.url else { return }
        uiImage = UIImage(data: data)
    }
}

// MARK: - Featured Article Card

private struct WMFFeaturedArticleCard: View {

    let article: WMFFeedArticle
    let theme: WMFTheme

    @StateObject private var imageViewModel = WMFCommunityImageLoader()

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
        .task(id: imageURL) {
            await imageViewModel.load(url: imageURL)
        }
    }

    private var imageURL: URL? {
        (article.thumbnail?.source ?? article.originalImage?.source).flatMap(URL.init(string:))
    }
}


// MARK: - News Story Card

private struct WMFNewsStoryCard: View {

    let story: String
    let imageURLString: String?
    let theme: WMFTheme

    @StateObject private var imageViewModel = WMFCommunityImageLoader()

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
        .task(id: imageURLString) {
            await imageViewModel.load(url: imageURLString.flatMap(URL.init(string:)))
        }
    }
}


// MARK: - Picture of the Day Card

private struct WMFPictureOfTheDayCard: View {

    let imageSource: WMFFeedImageSource
    /// The picture's description, drawn over the bottom of the image as on the Explore card.
    let caption: String?
    let theme: WMFTheme

    @StateObject private var imageViewModel = WMFCommunityImageLoader()

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
        .task(id: imageSource.source) {
            await imageViewModel.load(url: imageSource.source.flatMap(URL.init(string:)))
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
    static let dateToModuleSpacing: CGFloat = 12
    /// Between the last module and "See past community content".
    static let footerSpacing: CGFloat = 16

    static let disclaimerGlobeSize: CGFloat = 44

    static let featuredArticleImageHeight: CGFloat = 200
    static let newsCardHeight: CGFloat = 200
    static let pictureOfTheDayHeight: CGFloat = 300
}

// MARK: - iPad columns layout

/// The two iPad columns of a day, side by side at equal width, and the optional footer. The footer
/// is centered on the trailing column (the right one in a left-to-right feed), `footerSpacing`
/// below that column's last module. When the leading column is longer, the footer sits beside it,
/// so no tall blank space opens above the footer.
///
/// Subviews, in order: the leading column, the trailing column, then the footer if there is one.
private struct WMFCommunityColumnsLayout: Layout {
    let footerSpacing: CGFloat

    private struct Metrics {
        let columnWidth: CGFloat
        let leadingHeight: CGFloat
        let trailingHeight: CGFloat
        let footerHeight: CGFloat?

        var footerY: CGFloat { trailingHeight + footerSpacingIfAny }
        let footerSpacingIfAny: CGFloat
        var height: CGFloat {
            guard let footerHeight else { return max(leadingHeight, trailingHeight) }
            return max(leadingHeight, footerY + footerHeight)
        }
    }

    private func metrics(width: CGFloat, subviews: Subviews) -> Metrics {
        let columnWidth = width / 2
        let column = ProposedViewSize(width: columnWidth, height: nil)
        func height(_ index: Int) -> CGFloat {
            subviews.indices.contains(index) ? subviews[index].sizeThatFits(column).height : 0
        }
        return Metrics(
            columnWidth: columnWidth,
            leadingHeight: height(0),
            trailingHeight: height(1),
            footerHeight: subviews.count > 2 ? height(2) : nil,
            footerSpacingIfAny: subviews.count > 2 ? footerSpacing : 0
        )
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let metrics = metrics(width: width, subviews: subviews)
        return CGSize(width: width, height: metrics.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let metrics = metrics(width: bounds.width, subviews: subviews)
        let column = ProposedViewSize(width: metrics.columnWidth, height: nil)
        // Placed left to right. SwiftUI mirrors a custom layout in a right-to-left feed, so the
        // leading column ends up on the right there.
        if subviews.indices.contains(0) {
            subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.minY), anchor: .topLeading, proposal: column)
        }
        if subviews.indices.contains(1) {
            subviews[1].place(at: CGPoint(x: bounds.minX + metrics.columnWidth, y: bounds.minY), anchor: .topLeading, proposal: column)
        }
        if subviews.indices.contains(2) {
            subviews[2].place(at: CGPoint(x: bounds.minX + metrics.columnWidth, y: bounds.minY + metrics.footerY), anchor: .topLeading, proposal: column)
        }
    }
}

private extension WMFCommunityModule {
    /// The module's part of its UI-test accessibility identifiers.
    var accessibilityID: String {
        switch self {
        case .featuredArticle: return "featured_article"
        case .topRead: return "top_read"
        case .inTheNews: return "in_the_news"
        case .onThisDay: return "on_this_day"
        case .pictureOfDay: return "picture_of_the_day"
        }
    }
}

private extension View {
    @ViewBuilder
    func optionalAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}
