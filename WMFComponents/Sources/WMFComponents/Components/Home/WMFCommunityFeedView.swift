import SwiftUI
import WMFData

// MARK: - Community Feed View

struct WMFCommunityFeedView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    let feed: WMFCommunityResponse
    let project: WMFProject

    var body: some View {
        List {
            if let tfa = feed.feedResponse.todaysFeaturedArticle {
                featuredArticleSection(tfa)
            }

            if let mostRead = feed.feedResponse.mostRead, let articles = mostRead.articles, !articles.isEmpty {
                topReadSection(articles)
            }

            if let news = feed.feedResponse.news, !news.isEmpty {
                inTheNewsSection(news)
            }

            if let onThisDay = feed.onThisDay {
                onThisDaySection(onThisDay)
            }

            if let image = feed.feedResponse.image {
                pictureOfTheDaySection(image)
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: theme.paperBackground))
    }

    // MARK: - Featured Article

    private func featuredArticleSection(_ article: WMFFeedArticle) -> some View {
        Section {
            WMFFeaturedArticleCard(article: article, theme: theme)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color(uiColor: theme.paperBackground))
        } header: {
            sectionHeader("Featured Article")
        }
    }

    // MARK: - Top Read

    private func topReadSection(_ articles: [WMFFeedMostReadArticle]) -> some View {
        Section {
            ForEach(Array(articles.prefix(5).enumerated()), id: \.offset) { _, article in
                if let title = article.title ?? article.normalizedTitle {
                    let displayTitle = (try? HtmlUtils.stringFromHTML(article.displayTitle ?? title)) ?? title
                    WMFAsyncPageRow(viewModel: WMFAsyncPageRowViewModel(
                        id: title,
                        title: displayTitle,
                        projectID: project.id,
                        iconAccessibilityLabel: ""
                    ))
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color(uiColor: theme.paperBackground))
                }
            }
        } header: {
            sectionHeader("Top read")
        }
    }

    // MARK: - In The News

    private func inTheNewsSection(_ news: [WMFFeedNewsItem]) -> some View {
        Section {
            TabView {
                ForEach(Array(news.enumerated()), id: \.offset) { _, item in
                    WMFNewsStoryCard(story: item.story ?? "", theme: theme)
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
            sectionHeader("In the news")
        }
    }

    // MARK: - On This Day

    private func onThisDaySection(_ onThisDay: WMFOnThisDayResponse) -> some View {
        let currentYear = Calendar.current.component(.year, from: Date())
        let events = Array(onThisDay.events.prefix(2))
        return Section {
            ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(event.year)")
                        .font(Font(WMFFont.for(.boldTitle3)))
                        .foregroundStyle(Color(uiColor: theme.text))
                    Text("\(currentYear - event.year) years ago")
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                    Text(event.text)
                        .font(Font(WMFFont.for(.callout)))
                        .foregroundStyle(Color(uiColor: theme.text))
                    if !event.pages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 12) {
                                ForEach(Array(event.pages.enumerated()), id: \.offset) { _, page in
                                    WMFAsyncPageRow(viewModel: WMFAsyncPageRowViewModel(
                                        id: page.title,
                                        title: page.title,
                                        projectID: project.id,
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
            sectionHeader("On this day")
        }
    }

    // MARK: - Picture of the Day

    private func pictureOfTheDaySection(_ image: WMFFeedImageNew) -> some View {
        Section {
            WMFPictureOfTheDayCard(imageSource: image.thumbnail, theme: theme)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color(uiColor: theme.paperBackground))
        } header: {
            sectionHeader("Picture of the day")
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Font(WMFFont.for(.boldTitle3)))
            .foregroundStyle(Color(uiColor: theme.text))
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
            Text((try? HtmlUtils.stringFromHTML(story)) ?? story)
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

    let imageSource: WMFFeedImageSource?
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
            if let urlString = imageSource?.source, let url = URL(string: urlString) {
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

