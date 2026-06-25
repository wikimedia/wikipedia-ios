import SwiftUI
import WMFData

// MARK: - For You Feed View

public struct WMFForYouView: View {

    @ObservedObject public var viewModel: WMFForYouViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    let onRefresh: () async -> Void

    public init(viewModel: WMFForYouViewModel, onRefresh: @escaping () async -> Void) {
        self.viewModel = viewModel
        self.onRefresh = onRefresh
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.pages) { page in
                        WMFForYouTopicPageView(viewModel: page, theme: theme)
                            .frame(width: geometry.size.width, height: geometry.size.height)
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

// MARK: - Topic Page View

private struct WMFForYouTopicPageView: View {

    @ObservedObject var viewModel: WMFForYouPageViewModel
    let theme: WMFTheme

    var body: some View {
        TabView {
            ForEach(viewModel.articleViewModels) { article in
                WMFForYouArticleCardView(viewModel: article, theme: theme)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

// MARK: - Article Card View

private struct WMFForYouArticleCardView: View {

    @ObservedObject var viewModel: WMFForYouArticleCardViewModel
    let theme: WMFTheme

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
