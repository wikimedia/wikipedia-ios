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

// MARK: - For You Feed View

public struct WMFForYouView: View {

    @ObservedObject public var viewModel: WMFForYouViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFForYouViewModel) {
        self.viewModel = viewModel
    }

    private var visiblePages: [WMFForYouPageViewModel] {
        viewModel.pages.filter { viewModel.moduleVisibility.isVisible($0.module) }
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
                ForEach(visiblePages) { page in
                    let visibleArticles = page.articleViewModels.filter { !viewModel.hiddenCardKeys.contains($0.hideKey) }
                    if !visibleArticles.isEmpty {
                        WMFForYouPageView(
                            articleViewModels: visibleArticles,
                            theme: theme,
                            onHideModule: { viewModel.onHideModule?(page.module) },
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
        }
        .scrollTargetBehavior(.paging)
        .refreshable { await viewModel.onRefresh?() }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
                .padding(.bottom, 16)

            Text(viewModel.emptyTitle)
                .font(Font(WMFFont.for(.boldTitle3)))
                .foregroundStyle(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            Text(viewModel.emptySubtitle)
                .font(Font(WMFFont.for(.callout)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 24)

            Button {
                viewModel.onCustomizeInterests?()
            } label: {
                Text(viewModel.emptyButtonTitle)
                    .font(Font(WMFFont.for(.boldCallout)))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: theme.link), in: Capsule())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: theme.paperBackground))
    }
}

// MARK: - Header Label View

private struct WMFForYouHeaderLabelView: View {
    let headerLabel: WMFForYouHeaderLabel

    var body: some View {
        if let symbolName = headerLabel.symbolName {
            let icon = Text(Image(systemName: symbolName))
                .font(Font(WMFFont.for(.caption1)))
            let prefix = Text(" " + headerLabel.prefix)
                .font(Font(WMFFont.for(.caption1)))
            let suffix = Text(headerLabel.boldSuffix)
                .font(Font(WMFFont.for(.boldCaption1)))
            (icon + prefix + suffix)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(2)
                .minimumScaleFactor(0.35)
        } else {
            let prefix = Text(headerLabel.prefix)
                .font(Font(WMFFont.for(.caption1)))
            let suffix = Text(headerLabel.boldSuffix)
                .font(Font(WMFFont.for(.boldCaption1)))
            (prefix + suffix)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(2)
                .minimumScaleFactor(0.35)
        }
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

    @State private var currentPage: Int? = 0

    private var windowSafeAreaBottom: CGFloat {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first?.safeAreaInsets.bottom ?? 0
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(Array(articleViewModels.enumerated()), id: \.offset) { index, article in
                    let variant = WMFForYouCardVariant.variant(for: index)
                    WMFForYouArticleCardView(
                        viewModel: article,
                        variant: variant,
                        variantIndex: index,
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
                    .tag(index as Int?)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentPage)
        .overlay(alignment: .bottom) {
            HStack(spacing: 8) {
                ForEach(0..<articleViewModels.count, id: \.self) { index in
                    Circle()
                        .fill(index == (currentPage ?? 0) ? Color.white : Color.white.opacity(0.4))
                        .frame(
                            width: index == (currentPage ?? 0) ? 8 : 7,
                            height: index == (currentPage ?? 0) ? 8 : 7
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.vertical, 20)
            .padding(.bottom, windowSafeAreaBottom + 49 + 12)
        }
    }
}

// MARK: - Mini Card (Variant 3)

private struct WMFForYouMiniCard: View {
    let label: String
    let title: String
    let description: String?
    let uiImage: UIImage?
    let onMenu: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Font(WMFFont.for(.boldCaption1)))
                    .foregroundStyle(.white.opacity(0.5))
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

            Button(action: onMenu) {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.white)
                    .padding(8)
            }
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

    private var windowSafeAreaBottom: CGFloat {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first?.safeAreaInsets.bottom ?? 0
    }

    private var dotsAndTabBarHeight: CGFloat {
        windowSafeAreaBottom + 49 + 12 + 20 + 8 + 20
    }

    /// If the assigned variant requires an image but none is available, fall back to textFocused.
    private var effectiveVariant: WMFForYouCardVariant {
        if variant != .textFocused && viewModel.uiImage == nil {
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

    private var menuView: some View {
        Menu {
            Button {
                viewModel.toggleSaved()
                if viewModel.isSaved {
                    onSaveCard()
                } else {
                    onUnsaveCard()
                }
            } label: {
                Label(
                    viewModel.isSaved ? viewModel.unsaveTitle : viewModel.saveTitle,
                    systemImage: viewModel.isSaved ? "bookmark.fill" : "bookmark"
                )
            }
            Button { onShareCard() } label: {
                Label(viewModel.shareTitle, systemImage: "square.and.arrow.up")
            }
            Button(role: .destructive, action: onHideCard) {
                Label(viewModel.hideCardTitle, systemImage: "eye.slash")
            }
            Button(role: .destructive, action: onHideModule) {
                Label(viewModel.hideModuleTitle, systemImage: "xmark.circle")
            }
            Button(action: onCustomizeInterests) {
                Label(viewModel.customizeInterestsTitle, systemImage: "slider.horizontal.3")
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(.white)
                .shadow(radius: 2)
                .padding(12)
                .background(.ultraThinMaterial, in: Circle())
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
                        HStack(alignment: .top, spacing: 12) {
                            Text(viewModel.extract ?? viewModel.title)
                                .font(Font(WMFFont.for(.georgiaTitle1)))
                                .foregroundStyle(.white)
                                .lineLimit(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            menuView
                        }

                        Spacer().frame(height: 16)

                        WMFForYouMiniCard(
                            label: viewModel.miniCardLabel,
                            title: viewModel.title,
                            description: viewModel.description,
                            uiImage: viewModel.uiImage,
                            onMenu: onSaveCard
                        )

                        if !viewModel.headerLabel.prefix.isEmpty {
                            Spacer().frame(height: 16)
                            WMFForYouHeaderLabelView(headerLabel: viewModel.headerLabel)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, dotsAndTabBarHeight)
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
                            menuView
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

                        if !viewModel.headerLabel.prefix.isEmpty {
                            Spacer().frame(height: 16)
                            WMFForYouHeaderLabelView(headerLabel: viewModel.headerLabel)
                                .shadow(color: cardColor.opacity(0.8), radius: 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, dotsAndTabBarHeight)
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
            .overlay {
                if viewModel.loadState == .loading {
                    Color.clear
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: viewModel.loadState == .loading)
        }
    }
}
