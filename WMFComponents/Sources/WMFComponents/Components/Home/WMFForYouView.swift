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

    var body: some View {
        TabView {
            ForEach(articleViewModels) { article in
                WMFForYouArticleCardView(viewModel: article, theme: theme, onHideModule: onHideModule, onHideCard: { onHideCard(article) }, onCustomizeInterests: onCustomizeInterests)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

// MARK: - Article Card View

// MARK: - Article Card View

private struct WMFForYouArticleCardView: View {

    @ObservedObject var viewModel: WMFForYouArticleCardViewModel
    let theme: WMFTheme
    let onHideModule: () -> Void
    let onHideCard: () -> Void
    let onCustomizeInterests: () -> Void

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

                // cardColor is already AA compliant against white from sampling
                let cardColor = viewModel.sampledColor ?? Color.black

                // 2. Gradients at reduced opacity so image shows through
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

                // 3. Text on top, unblurred, full cardColor for AA compliance
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.headerLabel)
                        .font(Font(WMFFont.for(.boldSubheadline)))
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(color: cardColor.opacity(0.8), radius: 4)
                    Text(viewModel.title)
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundStyle(.white)
                        .shadow(color: cardColor.opacity(0.8), radius: 4)
                    if let description = viewModel.description {
                        Text(description)
                            .font(Font(WMFFont.for(.subheadline)))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(3)
                            .shadow(color: cardColor.opacity(0.8), radius: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 44)
                .frame(width: geometry.size.width, alignment: .leading)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay(alignment: .topTrailing) {
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
                        .padding(16)
                }
            }
            .clipped()
            .onAppear {
                viewModel.load()
            }
        }
    }
}
