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
    let onRefresh: () async -> Void
    let onTapSeePastContent: () -> Void
    let onTapArticle: (String, WMFProject) -> Void
    let onTapPictureOfTheDay: (Date) -> Void

    var scrollToTopRequestID: Int = 0

    /// Space at the top for the Home header that floats over the feed. The feed scrolls under the
    /// header, so this is a content margin and not a frame inset.
    var topContentInset: CGFloat = 0

    private static let topAnchorID = "community-feed-top"
    private static let horizontalPadding: CGFloat = 16

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
                LazyVStack(alignment: .leading, spacing: 24) {
                    // On iPad the disclaimer is drawn inside the first day's leading column, so the
                    // trailing column starts at the top beside it, as in the Figma.
                    if !usesTwoColumns || firstVisiblePageID == nil {
                        disclaimer
                            .id(Self.topAnchorID)
                    }
                    ForEach(pages) { page in
                        // A day whose modules are all off, hidden or missing would be a bare date.
                        let modules = page.visibleModules(visibility: moduleVisibility, hiddenCardKeys: hiddenCardKeys)
                        if !modules.isEmpty {
                            daySection(page, modules: modules, isFirstDay: page.id == firstVisiblePageID, isLastDay: page.id == lastVisiblePageID)
                        }
                    }
                    // On iPad the footer goes under the trailing column of the last day, as in the
                    // Figma. It is drawn here only when no day can hold it.
                    if !usesTwoColumns || lastVisiblePageID == nil {
                        footer
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
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
                .font(Font(WMFFont.for(.caption1)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Image(uiImage: WMFIcon.wikipediaGlobe ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: theme.midBackground))
        )
        .padding(.horizontal, Self.horizontalPadding)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Day

    @ViewBuilder
    /// The first day that shows any module. On iPad it holds the disclaimer.
    private var firstVisiblePageID: String? {
        pages.first { !$0.visibleModules(visibility: moduleVisibility, hiddenCardKeys: hiddenCardKeys).isEmpty }?.id
    }

    /// The last day that shows any module. On iPad it holds the footer.
    private var lastVisiblePageID: String? {
        pages.last { !$0.visibleModules(visibility: moduleVisibility, hiddenCardKeys: hiddenCardKeys).isEmpty }?.id
    }

    private func daySection(_ page: WMFHomeCommunityViewModel, modules: [WMFCommunityModule], isFirstDay: Bool, isLastDay: Bool) -> some View {
        Group {
            if usesTwoColumns {
                // The date heads the leading column, so the trailing column starts level with it,
                // and on the first day level with the disclaimer. VoiceOver reads the leading
                // column, then the trailing one. Each module pads itself, so the columns sit edge
                // to edge and their text lines up with the date.
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 16) {
                        if isFirstDay {
                            disclaimer
                                .id(Self.topAnchorID)
                                .padding(.bottom, 8)
                        }
                        dateHeader(page)
                        moduleColumn(modules.filter(\.isInLeadingColumn), page: page)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    VStack(alignment: .leading, spacing: 24) {
                        moduleColumn(modules.filter { !$0.isInLeadingColumn }, page: page)
                        if isLastDay {
                            footer
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    dateHeader(page)
                    moduleColumn(modules, page: page)
                }
            }
        }
    }

    private func dateHeader(_ page: WMFHomeCommunityViewModel) -> some View {
        Text(page.date)
            .font(Font(WMFFont.for(.caption1)))
            .foregroundStyle(Color(uiColor: theme.secondaryText))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Self.horizontalPadding)
            .accessibilityAddTraits(.isHeader)
    }

    private func moduleColumn(_ modules: [WMFCommunityModule], page: WMFHomeCommunityViewModel) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(modules, id: \.self) { module in
                moduleView(module, page: page)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func moduleView(_ module: WMFCommunityModule, page: WMFHomeCommunityViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            moduleHeader(module, page: page)
            moduleContent(module, page: page)
        }
    }

    // MARK: - Module content
    // Each module's own design is its own task. These keep the content that the feed showed before.

    @ViewBuilder
    private func moduleContent(_ module: WMFCommunityModule, page: WMFHomeCommunityViewModel) -> some View {
        switch module {
        case .featuredArticle:
            if let article = page.featuredArticle {
                articleButton(article.title, page: page) {
                    WMFFeaturedArticleCard(article: article, theme: theme)
                }
                .padding(.horizontal, Self.horizontalPadding)
            }
        case .topRead:
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(page.topReadItems.enumerated()), id: \.offset) { _, item in
                    // The row has its own tap gesture, which runs `tapAction`, so it is not wrapped
                    // in a button.
                    WMFAsyncPageRow(viewModel: WMFAsyncPageRowViewModel(
                        id: item.title,
                        title: item.displayTitle,
                        projectID: item.projectID,
                        iconAccessibilityLabel: "",
                        tapAction: { onTapArticle(item.title, page.project) }
                    ))
                }
            }
            .padding(.horizontal, Self.horizontalPadding)
        case .inTheNews:
            // The story card brings its own horizontal padding.
            TabView {
                ForEach(Array(page.newsItems.enumerated()), id: \.offset) { _, item in
                    articleButton(item.articleTitle, page: page) {
                        WMFNewsStoryCard(story: item.story, imageURLString: item.imageURLString, theme: theme)
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(maxWidth: .infinity)
            .frame(height: 200)
        case .onThisDay:
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array((page.onThisDayItems ?? []).enumerated()), id: \.offset) { _, item in
                    onThisDayEvent(item, page: page)
                }
            }
            .padding(.horizontal, Self.horizontalPadding)
        case .pictureOfDay:
            if let pictureOfDay = page.pictureOfDay {
                // Edge to edge on a phone. In an iPad column it is inset like the other modules.
                Button {
                    onTapPictureOfTheDay(page.feedDate)
                } label: {
                    WMFPictureOfTheDayCard(imageSource: pictureOfDay, theme: theme)
                        .clipShape(RoundedRectangle(cornerRadius: usesTwoColumns ? 8 : 0))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(module.title(languageCode: page.strings.languageCode))
                .padding(.horizontal, usesTwoColumns ? Self.horizontalPadding : 0)
            }
        }
    }

    private func onThisDayEvent(_ item: WMFHomeCommunityViewModel.OnThisDayItem, page: WMFHomeCommunityViewModel) -> some View {
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
            if !item.pages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Array(item.pages.enumerated()), id: \.offset) { _, eventPage in
                            WMFAsyncPageRow(viewModel: WMFAsyncPageRowViewModel(
                                id: eventPage.title,
                                title: eventPage.normalizedTitle ?? eventPage.title,
                                projectID: item.projectID,
                                iconAccessibilityLabel: "",
                                tapAction: { onTapArticle(eventPage.title, page.project) }
                            ))
                            .containerRelativeFrame(.horizontal) { width, _ in width * 0.8 }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    /// Opens `title` from the page's wiki when the reader taps `label`. Without a title, the label
    /// is drawn as it is and does nothing.
    @ViewBuilder
    private func articleButton<Label: View>(_ title: String?, page: WMFHomeCommunityViewModel, @ViewBuilder label: () -> Label) -> some View {
        if let title {
            Button {
                onTapArticle(title, page.project)
            } label: {
                label()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            label()
        }
    }

    // MARK: - Module header

    private func moduleHeader(_ module: WMFCommunityModule, page: WMFHomeCommunityViewModel) -> some View {
        let hideKey = page.hideKey(for: module)
        return HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(module.title(languageCode: page.strings.languageCode))
                    .font(Font(WMFFont.for(.boldHeadline)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .accessibilityAddTraits(.isHeader)
                Text(module.subtitle(languageCode: page.strings.languageCode))
                    .font(Font(WMFFont.for(.footnote)))
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)

            // The three-dot menu has its own task. It keeps the actions it had.
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
            } label: {
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .ellipsis) ?? UIImage())
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
                    .frame(minWidth: 44, minHeight: 44, alignment: .top)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(WMFHomeLocalizedStrings.moreOptions)
        }
        .padding(.horizontal, Self.horizontalPadding)
    }

    // MARK: - Footer

    @ViewBuilder
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
                    .frame(height: 200)
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
    let theme: WMFTheme

    @StateObject private var imageViewModel = WMFPictureOfTheDayImageViewModel()

    var body: some View {
        Group {
            if let uiImage = imageViewModel.uiImage {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            } else {
                Color(uiColor: theme.midBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
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
