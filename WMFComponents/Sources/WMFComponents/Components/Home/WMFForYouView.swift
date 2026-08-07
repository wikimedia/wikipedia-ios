import SwiftUI
import WMFData

// MARK: - Card Variant

private enum WMFForYouCardVariant {
    case balanced       // variant 1: image bg + extract (index 0, 3)
    case imageFocused   // variant 2: image bg + description only (index 1)
    case textFocused    // variant 3: no image + color bg + mini card (index 2)

    static func variant(for index: Int) -> WMFForYouCardVariant {
        switch index % 4 {
        case 0, 3: return .balanced
        case 1:    return .imageFocused
        case 2:    return .textFocused
        default:   return .balanced
        }
    }

    static let textFocusedBackgrounds: [Color] = [
        Color(uiColor: WMFColor.purple800),
        Color(uiColor: WMFColor.pink800),
        Color(uiColor: WMFColor.orange800)
    ]
}

// MARK: - Card Metrics

/// Where the page dots sit, and how much room a card must leave clear beneath its content.
private enum WMFForYouCardMetrics {

    static let tabBarHeight: CGFloat = 49
    static let dotsBottomGap: CGFloat = 12
    static let dotsVerticalPadding: CGFloat = 20
    static let dotDiameter: CGFloat = 8

    static func dotsBottomInset(safeAreaBottom: CGFloat) -> CGFloat {
        safeAreaBottom + tabBarHeight + dotsBottomGap
    }

    static func contentBottomInset(safeAreaBottom: CGFloat) -> CGFloat {
        dotsBottomInset(safeAreaBottom: safeAreaBottom) + dotsVerticalPadding + dotDiameter + dotsVerticalPadding
    }

    static var windowSafeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.bottom ?? 0
    }
}

// MARK: - For You Feed View

public struct WMFForYouView: View {

    @ObservedObject public var viewModel: WMFForYouViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    @State private var hasReportedCurrentDrag = false

    public init(viewModel: WMFForYouViewModel) {
        self.viewModel = viewModel
    }

    private struct VisiblePage: Identifiable {
        let page: WMFForYouPageViewModel
        let articles: [WMFForYouArticleCardViewModel]
        var id: UUID { page.id }
    }
    
    private var visiblePages: [VisiblePage] {
        viewModel.pages.compactMap { page in
            guard viewModel.moduleVisibility.isVisible(page.module) else { return nil }
            let articles = page.articleViewModels.filter { !viewModel.hiddenCardKeys.contains($0.hideKey) }
            guard !articles.isEmpty else { return nil }
            return VisiblePage(page: page, articles: articles)
        }
    }

    public var body: some View {
        if visiblePages.isEmpty {
            emptyState
        } else {
            GeometryReader { geometry in
                scrollView(geometry: geometry)
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func scrollView(geometry: GeometryProxy) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(visiblePages) { visiblePage in
                    WMFForYouPageView(
                        articleViewModels: visiblePage.articles,
                        theme: theme,
                        onHideModule: { viewModel.onHideModule?(visiblePage.page.module) },
                        onHideCard: { viewModel.onHideCard?($0) },
                        onCustomizeInterests: { viewModel.onCustomizeInterests?() },
                        onTapCard: { viewModel.onTapCard?($0) },
                        onSaveCard: { viewModel.onSaveCard?($0) },
                        onShareCard: { viewModel.onShareCard?($0) },
                        onUnsaveCard: { viewModel.onUnsaveCard?($0) }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .scrollTargetBehavior(.paging)
        .refreshable { await viewModel.onRefresh?() }
        .scrollBounceBehavior(.basedOnSize)
        // Observe so we can dismiss the reading list toast
        .simultaneousGesture(
            DragGesture(minimumDistance: 8)
                .onChanged { _ in
                    guard !hasReportedCurrentDrag else { return }
                    hasReportedCurrentDrag = true
                    viewModel.onUserInteraction?()
                }
                .onEnded { _ in hasReportedCurrentDrag = false }
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        // The shared empty state component, given the For You palette so it stays dark while the
        // app is on a light theme, and a nil image size so the SF Symbol keeps its own size.
        let emptyViewModel = WMFEmptyViewModel(
            localizedStrings: WMFEmptyViewModel.LocalizedStrings(
                title: viewModel.emptyTitle,
                subtitle: viewModel.emptySubtitle,
                titleFilter: nil,
                buttonTitle: viewModel.emptyButtonTitle,
                attributedFilterString: nil
            ),
            image: WMFSFSymbolIcon.for(symbol: .sparkles, font: .xxlTitleBold),
            imageColor: WMFTheme.forYou.secondaryText,
            numberOfFilters: nil,
            imageSize: nil
        )

        return WMFEmptyView(
            viewModel: emptyViewModel,
            type: .noItems,
            isScrollable: false,
            theme: .forYou,
            mainAction: { viewModel.onCustomizeInterests?() },
            usesCompactButton: true
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: WMFTheme.forYou.paperBackground))
    }
}

// MARK: - Header Label View

private struct WMFForYouHeaderLabelView: View {
    let headerLabel: WMFForYouHeaderLabel

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if let symbol = headerLabel.symbol,
               let image = WMFSFSymbolIcon.for(symbol: symbol, font: .caption1) {
                Image(uiImage: image)
            }
            Text(attributedLabel)
        }
        .foregroundStyle(.white.opacity(0.8))
        .lineLimit(2)
        .minimumScaleFactor(0.35)
    }

    private var attributedLabel: AttributedString {
        let regularFont = Font(WMFFont.for(.caption1))
        let boldFont = Font(WMFFont.for(.boldCaption1))

        var highlight = AttributedString(headerLabel.highlight)
        highlight.font = boldFont

        let placeholder = headerLabel.format.contains("%1$@") ? "%1$@" : "%@"
        let parts = headerLabel.format.components(separatedBy: placeholder)

        guard parts.count == 2 else {
            var whole = AttributedString(String.localizedStringWithFormat(headerLabel.format, headerLabel.highlight))
            whole.font = regularFont
            return whole
        }

        var leading = AttributedString(parts[0])
        leading.font = regularFont
        var trailing = AttributedString(parts[1])
        trailing.font = regularFont

        return leading + highlight + trailing
    }
}

// MARK: - Page View

private struct WMFForYouPageView: View {

    let articleViewModels: [WMFForYouArticleCardViewModel]
    let theme: WMFTheme
    let onHideModule: () -> Void
    let onHideCard: (WMFForYouArticleCardViewModel) -> Void
    let onCustomizeInterests: () -> Void
    let onTapCard: (WMFForYouArticleCardViewModel) -> Void
    let onSaveCard: (WMFForYouArticleCardViewModel) -> Void
    let onShareCard: (WMFForYouArticleCardViewModel) -> Void
    let onUnsaveCard: (WMFForYouArticleCardViewModel) -> Void

    /// Identified by `hideKey` rather than by position, so that a card keeps its identity when an
    /// earlier card in the carousel is hidden.
    @State private var currentPage: String?

    /// `scrollPosition` only writes to `currentPage` once the user scrolls, so fall back to the
    /// first card to keep the page dots correct on first appearance.
    private var currentPageKey: String? {
        currentPage ?? articleViewModels.first?.hideKey
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(articleViewModels, id: \.hideKey) { article in
                    let variant = WMFForYouCardVariant.variant(for: article.cardIndex)
                    WMFForYouArticleCardView(
                        viewModel: article,
                        variant: variant,
                        variantIndex: article.cardIndex,
                        theme: theme,
                        onHideModule: onHideModule,
                        onHideCard: { onHideCard(article) },
                        onCustomizeInterests: onCustomizeInterests,
                        onTapCard: { onTapCard(article) },
                        onSaveCard: { onSaveCard(article) },
                        onUnsaveCard: { onUnsaveCard(article) },
                        onShareCard: { onShareCard(article) }
                    )
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentPage)
        .overlay(alignment: .bottom) {
            HStack(spacing: 8) {
                ForEach(articleViewModels, id: \.hideKey) { article in
                    let isCurrent = article.hideKey == currentPageKey
                    Circle()
                        .fill(isCurrent ? Color.white : Color.white.opacity(0.4))
                        .frame(
                            width: isCurrent ? WMFForYouCardMetrics.dotDiameter : WMFForYouCardMetrics.dotDiameter - 1,
                            height: isCurrent ? WMFForYouCardMetrics.dotDiameter : WMFForYouCardMetrics.dotDiameter - 1
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPageKey)
                }
            }
            .padding(.vertical, WMFForYouCardMetrics.dotsVerticalPadding)
            .padding(.bottom, WMFForYouCardMetrics.dotsBottomInset(safeAreaBottom: WMFForYouCardMetrics.windowSafeAreaBottom))
        }
    }
}

// MARK: - Mini Card (Variant 3)

private struct WMFForYouMiniCard<Menu: View>: View {
    let title: String
    let description: String?
    let uiImage: UIImage?
    @ViewBuilder let menu: () -> Menu

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Font(WMFFont.for(.boldSubheadline)))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let description {
                    Text(description)
                        .font(Font(WMFFont.for(.caption1)))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.15))
                    .frame(width: 56, height: 56)
            }

            menu()
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Article Card View

private struct WMFForYouArticleCardView: View {

    @ObservedObject var viewModel: WMFForYouArticleCardViewModel
    let variant: WMFForYouCardVariant
    let variantIndex: Int
    let theme: WMFTheme
    let onHideModule: () -> Void
    let onHideCard: () -> Void
    let onCustomizeInterests: () -> Void
    let onTapCard: () -> Void
    let onSaveCard: () -> Void
    let onUnsaveCard: () -> Void
    let onShareCard: () -> Void

    /// If the assigned variant requires an image but none is available, fall back to textFocused.
    ///
    /// This reads `imageAvailability` rather than `uiImage`, because `uiImage` is nil for every
    /// card until its download finishes. Checking `uiImage` made every image card start as a text
    /// card and then change design mid-swipe. Only a genuinely missing or failed image falls back.
    private var effectiveVariant: WMFForYouCardVariant {
        if variant != .textFocused && viewModel.imageAvailability == .unavailable {
            return .textFocused
        }
        return variant
    }

    private var cardColor: Color {
        switch effectiveVariant {
        case .textFocused:
            return WMFForYouCardVariant.textFocusedBackgrounds[variantIndex % WMFForYouCardVariant.textFocusedBackgrounds.count]
        default:
            return viewModel.sampledColor ?? Color.black
        }
    }

    @ViewBuilder
    private func overflowMenu<MenuLabel: View>(@ViewBuilder label: @escaping () -> MenuLabel) -> some View {
        Menu {
            Button {
                viewModel.toggleSaved()
                if viewModel.isSaved {
                    onSaveCard()
                } else {
                    onUnsaveCard()
                }
            } label: {
                Label {
                    Text(viewModel.isSaved ? viewModel.unsaveTitle : viewModel.saveTitle)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: viewModel.isSaved ? .bookmarkFill : .bookmark) ?? UIImage())
                }
            }
            Button { onShareCard() } label: {
                Label {
                    Text(viewModel.shareTitle)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .squareAndArrowUp) ?? UIImage())
                }
            }
            Button(role: .destructive, action: onHideCard) {
                Label {
                    Text(viewModel.hideCardTitle)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .eyeSlash) ?? UIImage())
                }
            }
            Button(role: .destructive, action: onHideModule) {
                Label {
                    Text(viewModel.hideModuleTitle)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .xmarkCircle) ?? UIImage())
                }
            }
            Button(action: onCustomizeInterests) {
                Label {
                    Text(viewModel.customizeInterestsTitle)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .sliderHorizontal3) ?? UIImage())
                }
            }
        } label: {
            label()
        }
    }

    private var floatingMenu: some View {
        overflowMenu {
            Image(uiImage: WMFSFSymbolIcon.for(symbol: .ellipsis) ?? UIImage())
                .foregroundStyle(.white)
                .shadow(radius: 2)
                .padding(12)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private var miniCardMenu: some View {
        overflowMenu {
            Image(uiImage: WMFSFSymbolIcon.for(symbol: .ellipsis) ?? UIImage())
                .foregroundStyle(.white)
                .padding(8)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {

                // 1. Background
                Group {
                    switch effectiveVariant {
                    case .textFocused:
                        cardColor
                    default:
                        if let uiImage = viewModel.uiImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            cardColor
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .ignoresSafeArea()

                // 2. Content
                switch effectiveVariant {

                // MARK: Variant 3: Text-focused (also used as fallback when no image)
                case .textFocused:
                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewModel.extract ?? viewModel.title)
                            .font(Font(WMFFont.for(.georgiaTitle1)))
                            .foregroundStyle(.white)
                            .lineLimit(8)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer().frame(height: 16)

                        WMFForYouMiniCard(
                            title: viewModel.title,
                            description: viewModel.description,
                            uiImage: viewModel.uiImage,
                            menu: { miniCardMenu }
                        )

                        if !viewModel.headerLabel.format.isEmpty {
                            Spacer().frame(height: 16)
                            WMFForYouHeaderLabelView(headerLabel: viewModel.headerLabel)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, WMFForYouCardMetrics.contentBottomInset(safeAreaBottom: WMFForYouCardMetrics.windowSafeAreaBottom))
                    .frame(width: geometry.size.width, alignment: .leading)

                // MARK: Variant 1 & 2: Image-backed
                default:
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top, spacing: 12) {
                            Text(viewModel.title)
                                .font(Font(WMFFont.for(.georgiaTitle1)))
                                .foregroundStyle(.white)
                                .shadow(color: cardColor.opacity(0.8), radius: 4)
                                .lineLimit(effectiveVariant == .imageFocused ? 1 : 3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            floatingMenu
                        }

                        let bodyText: String? = {
                            switch effectiveVariant {
                            case .balanced:     return viewModel.extract ?? viewModel.description
                            case .imageFocused: return viewModel.description
                            default:            return nil
                            }
                        }()

                        if let bodyText {
                            Spacer().frame(height: 12)
                            Text(bodyText)
                                .font(Font(WMFFont.for(.body)))
                                .foregroundStyle(.white.opacity(0.9))
                                .shadow(color: cardColor.opacity(0.8), radius: 4)
                                .lineLimit(effectiveVariant == .imageFocused ? 2 : 5)
                        }

                        if !viewModel.headerLabel.format.isEmpty {
                            Spacer().frame(height: 16)
                            WMFForYouHeaderLabelView(headerLabel: viewModel.headerLabel)
                                .shadow(color: cardColor.opacity(0.8), radius: 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, WMFForYouCardMetrics.contentBottomInset(safeAreaBottom: WMFForYouCardMetrics.windowSafeAreaBottom))
                    .frame(width: geometry.size.width, alignment: .leading)
                    .background {
                        LinearGradient(
                            stops: [
                                .init(color: cardColor.opacity(0), location: 0.0),
                                .init(color: cardColor.opacity(0.75), location: 0.12),
                                .init(color: .black, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .padding(.top, -25)
                        .allowsHitTesting(false)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .ignoresSafeArea()
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture { onTapCard() }
            .onAppear { viewModel.load() }
            // Fades the photograph and its sampled colour in when the card finishes loading.
            .animation(.easeOut(duration: 0.2), value: viewModel.loadState == .loading)
        }
    }
}
