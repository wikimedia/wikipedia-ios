import SwiftUI
import WidgetKit
import WMF

// MARK: - Widget

struct TopReadWidget: Widget {
    private let kind: String = WidgetController.SupportedWidget.topRead.identifier

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TopReadProvider(), content: { entry in
            TopReadView(entry: entry)
        })
        .configurationDisplayName(LocalizedStrings.widgetTitle)
        .description(LocalizedStrings.widgetDescription)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Data

final class TopReadData {

    // MARK: Properties

    static let shared = TopReadData()

    let maximumRankedArticles = 4

    var placeholder: TopReadEntry {
        return TopReadEntry(date: Date())
    }

    func fetchLatestAvailableTopRead(usingCache: Bool = false, completion userCompletion: @escaping (TopReadEntry) -> Void) {
        let widgetController = WidgetController.shared
        widgetController.startWidgetUpdateTask(userCompletion) { (dataStore, widgetUpdateTaskCompletion) in
            widgetController.fetchNewestWidgetContentGroup(with: .topRead, in: dataStore, isNetworkFetchAllowed: !usingCache) { (contentGroup) in
                guard let contentGroup = contentGroup else {
                    widgetUpdateTaskCompletion(self.placeholder)
                    return
                }
                self.assembleTopReadFromContentGroup(contentGroup, with: dataStore, usingImageCache: usingCache, completion: widgetUpdateTaskCompletion)
            }
        }
    }

    // MARK: Private
    
    private func assembleTopReadFromContentGroup(_ topRead: WMFContentGroup, with dataStore: MWKDataStore, usingImageCache: Bool = false, completion: @escaping (TopReadEntry) -> Void) {
        guard let results = topRead.contentPreview as? [WMFFeedTopReadArticlePreview] else {
            completion(placeholder)
            return
        }

        // The WMFContentGroup can only be accessed synchronously
        // re-accessing it from the main queue or another queue might lead to unexpected behavior
        let layoutDirection: LayoutDirection = topRead.isRTL ? .rightToLeft : .leftToRight
        let groupURL = topRead.url
        let isCurrent = topRead.isForToday // even though the top read data is from yesterday, the content group is for today
        var rankedElements: [TopReadEntry.RankedElement] = []
        for article in results {
            if let articlePreview = dataStore.fetchArticle(with: article.articleURL) {
                if let viewCounts = articlePreview.pageViewsSortedByDate {
                    rankedElements.append(.init(title: article.displayTitle, description: article.wikidataDescription ?? article.snippet ?? "", articleURL: article.articleURL, thumbnailURL: article.thumbnailURL, viewCounts: viewCounts))
                }
            }
        }

        rankedElements = Array(rankedElements.prefix(maximumRankedArticles))

        let group = DispatchGroup()

        for (index, element) in rankedElements.enumerated() {
            group.enter()
            guard let thumbnailURL = element.thumbnailURL else {
                group.leave()
                continue
            }
            
            let fetcher = dataStore.cacheController.imageCache
            
            if usingImageCache {
                if let cachedImage = fetcher.cachedImage(withURL: thumbnailURL) {
                    rankedElements[index].image = cachedImage.staticImage
                }
                group.leave()
                continue
            }

            fetcher.fetchImage(withURL: thumbnailURL, failure: { _ in
                group.leave()
            }, success: { fetchedImage in
                rankedElements[index].image = fetchedImage.image.staticImage
                group.leave()
            })
        }

        group.notify(queue: .main) {
            completion(TopReadEntry(date: Date(), rankedElements: rankedElements, groupURL: groupURL, isCurrent: isCurrent, contentLayoutDirection: layoutDirection))
        }
    }

}

// MARK: - Model

struct TopReadEntry: TimelineEntry {
    struct RankedElement: Identifiable {
        var id: String = UUID().uuidString

        let title: String
        let description: String
        var articleURL: URL? = nil
        var image: UIImage? = nil
        var thumbnailURL: URL? = nil
        let viewCounts: [NSNumber]
    }

    let date: Date // for Timeline Entry
    var rankedElements: [RankedElement] = Array(repeating: RankedElement.init(title: "–", description: "–", image: nil, viewCounts: [.init(floatLiteral: 0)]), count: 4)
    var groupURL: URL? = nil
    var isCurrent: Bool = false
    var contentLayoutDirection: LayoutDirection = .leftToRight
}

// MARK: - TimelineProvider

struct TopReadProvider: TimelineProvider {

    // MARK: Nested Types

    public typealias Entry = TopReadEntry

    // MARK: Properties

    private let dataStore = TopReadData.shared

    // MARK: TimelineProvider

    func placeholder(in: Context) -> TopReadEntry {
        return dataStore.placeholder
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TopReadEntry>) -> Void) {
        dataStore.fetchLatestAvailableTopRead { entry in
            let isError = entry.groupURL == nil || !entry.isCurrent
            let nextUpdate: Date
            let currentDate = Date()
            if !isError {
                nextUpdate = currentDate.randomDateShortlyAfterMidnight() ?? currentDate
            } else {
                let components = DateComponents(hour: 2)
                nextUpdate = Calendar.current.date(byAdding: components, to: currentDate) ?? currentDate
            }
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    func getSnapshot(in context: Context, completion: @escaping (TopReadEntry) -> Void) {
        dataStore.fetchLatestAvailableTopRead(usingCache: context.isPreview) { (entry) in
            completion(entry)
        }
    }

}

// MARK: - Views

struct TopReadView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    var entry: TopReadProvider.Entry?

    var readersTextColor: Color {
        colorScheme == .light
            ? Theme.light.colors.rankGradientEnd.asColor
            : Theme.dark.colors.rankGradientEnd.asColor
    }

    @ViewBuilder
    var body: some View {
        GeometryReader { proxy in
            switch family {
            case .systemMedium:
                rowBasedWidget(.systemMedium)
                    .widgetURL(entry?.groupURL)
            case .systemLarge:
                rowBasedWidget(.systemLarge)
                    .widgetURL(entry?.groupURL)
            default:
                smallWidget
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
                    .overlay(TopReadOverlayView(rankedElement: entry?.rankedElements.first))
                    .widgetURL(entry?.rankedElements.first?.articleURL)
            }
        }
        .environment(\.layoutDirection, entry?.contentLayoutDirection ?? .leftToRight)
        .flipsForRightToLeftLayoutDirection(true)
    }

    // MARK: View Components

    @ViewBuilder
    var smallWidget: some View {
        if let image = entry?.rankedElements.first?.image {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            Rectangle()
                .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
        }
    }

    @ViewBuilder
    func rowBasedWidget(_ family: WidgetFamily) -> some View {
        let showSparkline = family == .systemLarge ? true : false
        let rowCount = family == .systemLarge ? 4 : 2

        VStack(alignment: .leading, spacing: 8) {
            Text(TopReadWidget.LocalizedStrings.widgetTitle)
                .font(.subheadline)
                .fontWeight(.bold)
            ForEach(entry?.rankedElements.indices.prefix(rowCount) ?? 0..<0) { elementIndex in
                if let articleURL = entry?.rankedElements[elementIndex].articleURL {
                    Link(destination: articleURL, label: {
                        elementRow(elementIndex, rowCount: rowCount, showSparkline: showSparkline)
                    })
                } else {
                    elementRow(elementIndex, rowCount: rowCount, showSparkline: showSparkline)
                }
            }
        }
        .padding(16)
    }

    @ViewBuilder
    func elementRow(_ index: Int, rowCount: Int, showSparkline: Bool = false) -> some View {
        let rankColor = colorScheme == .light ? Theme.light.colors.rankGradient.color(at: CGFloat(index)/CGFloat(rowCount)).asColor : Theme.dark.colors.rankGradient.color(at: CGFloat(index)/CGFloat(rowCount)).asColor
        GeometryReader { proxy in
            HStack(alignment: .center) {
                Circle()
                    .strokeBorder(rankColor, lineWidth: 1)
                    .frame(width: 22, height: 22, alignment: .leading)
                    .overlay(
                        Text("\(NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: index + 1)))")
                            .font(.footnote)
                            .fontWeight(.light)
                            .foregroundColor(rankColor)
                    )
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 7))
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(entry?.rankedElements[index].title ?? "–")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.label))
                    if showSparkline {
                        Text("\(entry?.rankedElements[index].description ?? "–")")
                            .lineLimit(2)
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                        Sparkline(style: .compactWithViewCount, timeSeries: entry?.rankedElements[index].viewCounts)
                            .cornerRadius(4)
                            .frame(height: proxy.size.height / 3.0, alignment: .leading)
                    } else {
                        Text("\(numberOfReadersTextOrEmptyForViewCount(entry?.rankedElements[index].viewCounts.last))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .foregroundColor(readersTextColor)
                    }
                }
                Spacer()
                elementImageOrEmptyView(index)
                    .frame(width: proxy.size.height / 1.1, height: proxy.size.height / 1.1, alignment: .trailing)
                    .mask(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                    )
            }
        }
    }

    @ViewBuilder
    func elementImageOrEmptyView(_ elementIndex: Int) -> some View {
        if let image = entry?.rankedElements[elementIndex].image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            EmptyView()
        }
    }

    // MARK: Private

    private func numberOfReadersTextOrEmptyForViewCount(_ viewCount: NSNumber?) -> String {
        guard let viewCount = viewCount else {
            return "–"
        }
        
        let formattedCount = NumberFormatter.localizedThousandsStringFromNumber(viewCount)
        return String.localizedStringWithFormat(TopReadWidget.LocalizedStrings.readersCountFormat, formattedCount)
    }
}

struct TopReadOverlayView: View {
    @Environment(\.colorScheme) var colorScheme

    var rankedElement: TopReadEntry.RankedElement?

    var isExpandedStyle: Bool {
        return rankedElement?.image == nil
    }

    var readersForegroundColor: Color {
        colorScheme == .light
            ? Theme.light.colors.rankGradientEnd.asColor
            : Theme.dark.colors.rankGradientEnd.asColor
    }

    var primaryTextColor: Color {
        isExpandedStyle
            ? colorScheme == .dark ? Color.white : Color.black
            : .white
    }

    private var currentNumberOfReadersTextOrEmpty: String {
        guard let currentViewCount = rankedElement?.viewCounts.last else {
            return "–"
        }

        let formattedCount = NumberFormatter.localizedThousandsStringFromNumber(currentViewCount)
        return String.localizedStringWithFormat(TopReadWidget.LocalizedStrings.readersCountFormat, formattedCount)
    }

    var body: some View {
        if isExpandedStyle {
            content
        } else {
            content
                .background(
                    Rectangle()
                        .foregroundColor(.black)
                        .mask(LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .center, endPoint: .bottom))
                        .opacity(0.35)
                )
        }
    }

    // MARK: View Components

    var content: some View {
        VStack(alignment: .leading) {
            if isExpandedStyle {
                Text(currentNumberOfReadersTextOrEmpty)
                    .fontWeight(.medium)
                    .lineLimit(nil)
                    .font(.subheadline)
                    .foregroundColor(readersForegroundColor)
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 0))
            }
            sparkline(expanded: isExpandedStyle)
            Spacer()
            description()
        }
        .foregroundColor(.white)
    }

    func sparkline(expanded: Bool) -> some View {
        HStack(alignment: .top) {
            Spacer()
            if expanded {
                Sparkline(style: .expanded, timeSeries: rankedElement?.viewCounts)
                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 16))
            } else {
                Sparkline(style: .compact, timeSeries: rankedElement?.viewCounts)
                    .cornerRadius(4)
                    .frame(height: 20, alignment: .trailing)
                    .padding(EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 16))
                // TODO: Apply shadow just to final content – not children views as well
                // .clipped()
                // .readableShadow(intensity: 0.60)
            }
        }
    }

    func description() -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(TopReadWidget.LocalizedStrings.widgetTitle)
                .font(.caption2)
                .fontWeight(.heavy)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(primaryTextColor)
                .readableShadow(intensity: isExpandedStyle ? 0 : 0.8)
            Text("\(rankedElement?.title ?? "–")")
                .lineLimit(nil)
                .font(.headline)
                .foregroundColor(primaryTextColor)
                .readableShadow(intensity: isExpandedStyle ? 0 : 0.8)
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
    }
}
