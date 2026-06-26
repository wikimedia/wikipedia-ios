import SwiftUI
import WMFData

// MARK: - Community Feed View

struct WMFCommunityFeedView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    let pages: [WMFHomeCommunityViewModel]
    let moduleVisibility: WMFCommunityModuleVisibility
    let hiddenCardKeys: Set<String>
    let isLoadingPreviousPage: Bool
    let onHideModule: (WMFCommunityModule) -> Void
    let onHideCard: (String) -> Void
    let onRefresh: () async -> Void
    let onTapSeePastContent: () -> Void

    var body: some View {
        List {
            ForEach(Array(pages.enumerated()), id: \.offset) { _, page in
                dateSection(page.date)
                if moduleVisibility.featuredArticle,
                   let tfa = page.featuredArticle,
                   !hiddenCardKeys.contains(page.featuredArticleHideKey ?? "") {
                    featuredArticleSection(tfa, hideKey: page.featuredArticleHideKey)
                }
                if moduleVisibility.topRead,
                   !page.topReadItems.isEmpty,
                   !hiddenCardKeys.contains(page.topReadHideKey) {
                    topReadSection(page.topReadItems, hideKey: page.topReadHideKey)
                }
                if moduleVisibility.inTheNews,
                   !page.newsItems.isEmpty,
                   !hiddenCardKeys.contains(page.inTheNewsHideKey) {
                    inTheNewsSection(page.newsItems, hideKey: page.inTheNewsHideKey)
                }
                if moduleVisibility.onThisDay,
                   let onThisDayItems = page.onThisDayItems,
                   !hiddenCardKeys.contains(page.onThisDayHideKey) {
                    onThisDaySection(onThisDayItems, hideKey: page.onThisDayHideKey)
                }
                if moduleVisibility.pictureOfDay,
                   let pictureOfDay = page.pictureOfDay,
                   !hiddenCardKeys.contains(page.pictureOfDayHideKey ?? "") {
                    pictureOfTheDaySection(pictureOfDay, hideKey: page.pictureOfDayHideKey)
                }
            }

            Section {
                if isLoadingPreviousPage {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color(uiColor: theme.paperBackground))
                } else {
                    Button(action: onTapSeePastContent) {
                        Text("See past community content")
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                            .foregroundStyle(Color(uiColor: theme.link))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(uiColor: theme.paperBackground))
                }
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: theme.paperBackground))
        .refreshable {
            await onRefresh()
        }
    }

    // MARK: - Date Callout

    private func dateSection(_ dateString: String) -> some View {
        Section {
            Text(dateString)
                .font(Font(WMFFont.for(.boldTitle1)))
                .foregroundStyle(Color(uiColor: theme.text))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color(uiColor: theme.paperBackground))
        }
    }

    // MARK: - Featured Article

    private func featuredArticleSection(_ article: WMFFeedArticle, hideKey: String?) -> some View {
        Section {
            WMFFeaturedArticleCard(article: article, theme: theme)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color(uiColor: theme.paperBackground))
        } header: {
            sectionHeader("Featured Article", module: .featuredArticle, hideKey: hideKey)
        }
    }

    // MARK: - Top Read

    private func topReadSection(_ items: [WMFHomeCommunityViewModel.TopReadItem], hideKey: String) -> some View {
        Section {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                WMFAsyncPageRow(viewModel: WMFAsyncPageRowViewModel(
                    id: item.title,
                    title: item.displayTitle,
                    projectID: item.projectID,
                    iconAccessibilityLabel: ""
                ))
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color(uiColor: theme.paperBackground))
            }
        } header: {
            sectionHeader("Top read", module: .topRead, hideKey: hideKey)
        }
    }

    // MARK: - In The News

    private func inTheNewsSection(_ items: [WMFHomeCommunityViewModel.NewsItem], hideKey: String) -> some View {
        Section {
            TabView {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    WMFNewsStoryCard(story: item.story, theme: theme)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color(uiColor: theme.paperBackground))
        } header: {
            sectionHeader("In the news", module: .inTheNews, hideKey: hideKey)
        }
    }

    // MARK: - On This Day

    private func onThisDaySection(_ items: [WMFHomeCommunityViewModel.OnThisDayItem], hideKey: String) -> some View {
        Section {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(item.year)")
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
                                ForEach(Array(item.pages.enumerated()), id: \.offset) { _, page in
                                    WMFAsyncPageRow(viewModel: WMFAsyncPageRowViewModel(
                                        id: page.title,
                                        title: page.title,
                                        projectID: item.projectID,
                                        iconAccessibilityLabel: ""
                                    ))
                                    .containerRelativeFrame(.horizontal) { width, _ in width * 0.8 }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color(uiColor: theme.paperBackground))
            }
        } header: {
            sectionHeader("On this day", module: .onThisDay, hideKey: hideKey)
        }
    }

    // MARK: - Picture of the Day

    private func pictureOfTheDaySection(_ imageSource: WMFFeedImageSource, hideKey: String?) -> some View {
        Section {
            WMFPictureOfTheDayCard(imageSource: imageSource, theme: theme)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color(uiColor: theme.paperBackground))
        } header: {
            sectionHeader("Picture of the day", module: .pictureOfDay, hideKey: hideKey)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, module: WMFCommunityModule, hideKey: String?) -> some View {
        HStack {
            Text(title)
                .font(Font(WMFFont.for(.boldTitle3)))
                .foregroundStyle(Color(uiColor: theme.text))
            Spacer()
            Menu {
                Button(role: .destructive) {
                    if let hideKey { onHideCard(hideKey) }
                } label: {
                    Label("Hide this card", systemImage: "eye.slash")
                }
                .disabled(hideKey == nil)
                Button(role: .destructive) {
                    onHideModule(module)
                } label: {
                    Label("Hide module", systemImage: "xmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: theme.paperBackground))
        .listRowInsets(EdgeInsets())
        .textCase(nil)
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
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(8)
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
    let theme: WMFTheme

    var body: some View {
        ScrollView {
            Text(story)
                .font(Font(WMFFont.for(.callout)))
                .foregroundStyle(Color(uiColor: theme.text))
                .multilineTextAlignment(.leading)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: theme.midBackground))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
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
