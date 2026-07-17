import SwiftUI
import WMFData

// MARK: - For You Feed View

public struct WMFForYouView: View {

    @ObservedObject public var viewModel: WMFForYouViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    let moduleVisibility: WMFForYouModuleVisibility
    let hiddenCardKeys: Set<String>
    let onRefresh: () async -> Void
    let onHideModule: (WMFForYouModule) -> Void
    let onHideCard: (WMFForYouArticleCardViewModel) -> Void
    let onCustomizeInterests: () -> Void

    public init(viewModel: WMFForYouViewModel, moduleVisibility: WMFForYouModuleVisibility, hiddenCardKeys: Set<String> = [], onRefresh: @escaping () async -> Void, onHideModule: @escaping (WMFForYouModule) -> Void, onHideCard: @escaping (WMFForYouArticleCardViewModel) -> Void, onCustomizeInterests: @escaping () -> Void) {
        self.viewModel = viewModel
        self.moduleVisibility = moduleVisibility
        self.hiddenCardKeys = hiddenCardKeys
        self.onRefresh = onRefresh
        self.onHideModule = onHideModule
        self.onHideCard = onHideCard
        self.onCustomizeInterests = onCustomizeInterests
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.pages.filter { moduleVisibility.isVisible($0.module) }) { page in
                        let visibleArticles = page.articleViewModels.filter { !hiddenCardKeys.contains($0.hideKey) }
                        if !visibleArticles.isEmpty {
                            WMFForYouPageView(articleViewModels: visibleArticles, theme: theme, onHideModule: { onHideModule(page.module) }, onHideCard: onHideCard, onCustomizeInterests: onCustomizeInterests)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                }
            }
            .scrollTargetBehavior(.paging)
            .refreshable {
                await onRefresh()
            }
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

    @State private var currentPage: Int = 0

    private var windowSafeAreaBottom: CGFloat {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first?.safeAreaInsets.bottom ?? 0
    }

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(articleViewModels.enumerated()), id: \.element.id) { index, article in
                WMFForYouArticleCardView(viewModel: article, theme: theme, onHideModule: onHideModule, onHideCard: { onHideCard(article) }, onCustomizeInterests: onCustomizeInterests)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .bottom) {
            HStack(spacing: 8) {
                ForEach(0..<articleViewModels.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                        .frame(
                            width: index == currentPage ? 8 : 7,
                            height: index == currentPage ? 8 : 7
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.vertical, 20)
            .padding(.bottom, windowSafeAreaBottom + 49 + 12)
        }
    }
}

// MARK: - Article Card View

private struct WMFForYouArticleCardView: View {

    @ObservedObject var viewModel: WMFForYouArticleCardViewModel
    let theme: WMFTheme
    let onHideModule: () -> Void
    let onHideCard: () -> Void
    let onCustomizeInterests: () -> Void

    private var windowSafeAreaBottom: CGFloat {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first?.safeAreaInsets.bottom ?? 0
    }

    // dots (8pt) + vertical padding (20pt x2) + tab bar (49pt) + offset (12pt)
    private var dotsAndTabBarHeight: CGFloat {
        windowSafeAreaBottom + 49 + 12 + 20 + 8 + 20
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // 1. Background image
                Group {
                    if let uiImage = viewModel.uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color(uiColor: theme.midBackground)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()

                let cardColor = viewModel.sampledColor ?? Color.black

                // 2. Gradients + blur
                ZStack {
                    LinearGradient(
                        stops: [
                            .init(color: cardColor.opacity(0), location: 0.0),
                            .init(color: cardColor.opacity(0.6), location: 1.0)
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0.26),
                        endPoint: UnitPoint(x: 0.5, y: 0.15)
                    )
                    LinearGradient(
                        stops: [
                            .init(color: cardColor.opacity(0), location: 0.0),
                            .init(color: cardColor.opacity(0.85), location: 0.35)
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0.61),
                        endPoint: UnitPoint(x: 0.5, y: 0.92)
                    )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .drawingGroup()
                .blur(radius: 5)
                .animation(.easeInOut(duration: 0.3), value: viewModel.sampledColor)

                // 3. Content: title row, description, because of
                VStack(alignment: .leading, spacing: 0) {

                    // Title + menu
                    HStack(alignment: .top, spacing: 12) {
                        Text(viewModel.title)
                            .font(Font(WMFFont.for(.georgiaTitle1)))
                            .foregroundStyle(.white)
                            .shadow(color: cardColor.opacity(0.8), radius: 4)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Menu {
                            Button(action: onCustomizeInterests) {
                                Label("Customize interests", systemImage: "slider.horizontal.3")
                            }
                            Button(role: .destructive, action: onHideCard) {
                                Label("Hide this card", systemImage: "eye.slash")
                            }
                            Button(role: .destructive, action: onHideModule) {
                                Label("Hide module", systemImage: "xmark.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                                .padding(12)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }

                    if let extract = viewModel.extract {
                        Spacer().frame(height: 12)
                        Text(extract)
                            .font(Font(WMFFont.for(.body)))
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: cardColor.opacity(0.8), radius: 4)
                            .lineLimit(5)
                    }

                    if !viewModel.headerLabel.isEmpty {
                        Spacer().frame(height: 16)
                        // "Because of your interest: <Topic>"
                        // headerLabel is e.g. "Interest Topic: Visual arts"
                        // Split on ": " to style separately
                        let parts = viewModel.headerLabel.components(separatedBy: ": ")
                        if parts.count >= 2 {
                            let prefix = parts[0] + ": "
                            let interest = parts[1...].joined(separator: ": ")
                            (Text(prefix)
                                .font(Font(WMFFont.for(.caption1)))
                                .foregroundStyle(.white.opacity(0.8))
                             + Text(interest)
                                .font(Font(WMFFont.for(.boldCaption1)))
                                .foregroundStyle(.white.opacity(0.8)))
                            .shadow(color: cardColor.opacity(0.8), radius: 4)
                            .lineLimit(2)
                        } else {
                            Text(viewModel.headerLabel)
                                .font(Font(WMFFont.for(.caption1)))
                                .foregroundStyle(.white.opacity(0.8))
                                .shadow(color: cardColor.opacity(0.8), radius: 4)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, dotsAndTabBarHeight)
                .frame(width: geometry.size.width, alignment: .leading)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .onAppear {
                viewModel.load()
            }
        }
    }
}
