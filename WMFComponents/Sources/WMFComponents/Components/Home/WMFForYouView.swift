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

private struct WMFForYouArticleCardView: View {

    @ObservedObject var viewModel: WMFForYouArticleCardViewModel
    let theme: WMFTheme
    let onHideModule: () -> Void
    let onHideCard: () -> Void
    let onCustomizeInterests: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.headerLabel)
                    .font(Font(WMFFont.for(.boldSubheadline)))
                    .foregroundStyle(.white.opacity(0.8))
                    .shadow(radius: 2)
                Text(viewModel.title)
                    .font(Font(WMFFont.for(.boldTitle1)))
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                if let description = viewModel.description {
                    Text(description)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(3)
                        .shadow(radius: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 44)
        }
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
        .background {
            Group {
                if let uiImage = viewModel.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(uiColor: theme.midBackground)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            viewModel.load()
        }
    }
}
