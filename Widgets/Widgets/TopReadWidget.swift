import SwiftUI
import WMFComponents
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
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

// MARK: - Data

final class TopReadData {

    // MARK: Properties

    static let shared = TopReadData()

    var placeholder: TopReadEntry {
        return TopReadEntry(isPlaceholder: true, date: Date())
    }

    // MARK: - Public

    func fetchTopReadEntryData(usingCache: Bool = false, completion: @escaping (TopReadEntry) -> Void) {
        let widgetController = WidgetController.shared
        widgetController.fetchTopReadContent(isSnapshot: usingCache) { result in
            switch result {
            case .success(let topReadContent):
                let topFourElements = topReadContent.topFourElements
                let layoutDirection: LayoutDirection = (topFourElements.first?.isRTL ?? false) ? .rightToLeft : .leftToRight
                var rankedElements: [TopReadEntry.RankedElement] = []

                let midnightUTCDate: Date
                let backupMidnightDate: Date = (Date() as NSDate).wmf_midnightUTCDateFromLocal ?? Date()
                let utcDateFormatter = DateFormatter.wmf_utcMonthNameDayOfMonthNumber()

                if let dateString = topReadContent.dateString {
                    midnightUTCDate = utcDateFormatter?.date(from: dateString) ?? backupMidnightDate
                } else {
                    midnightUTCDate = backupMidnightDate
                }

                let groupURL = WMFContentGroup.topReadURL(forSiteURL: widgetController.featuredContentSiteURL, midnightUTCDate: midnightUTCDate)

                for rankedElement in topFourElements {
                    let title = rankedElement.displayTitle.removingHTML
                    let description = rankedElement.description?.removingHTML ?? ""
                    let url = URL(string: rankedElement.contentURL.desktop.page)
                    let viewCounts: [NSNumber] = rankedElement.viewHistory.compactMap { NSNumber(value: $0.views) }
                    var image: UIImage?
                    if let imageData = rankedElement.thumbnailImageSource?.data {
                        image = UIImage(data: imageData)
                    }

                    let displayElement = TopReadEntry.RankedElement(title: title, description: description, articleURL: url, image: image, viewCounts: viewCounts)
                    rankedElements.append(displayElement)
                }

                completion(TopReadEntry(date: Date(), rankedElements: rankedElements, groupURL: groupURL, contentLayoutDirection: layoutDirection))
            case .failure:
                completion(self.placeholder)
            }
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
        let viewCounts: [NSNumber]
    }

    var isPlaceholder: Bool = false

    let date: Date // for Timeline Entry
    var rankedElements: [RankedElement] = Array(repeating: RankedElement.init(title: "–", description: "–", image: nil, viewCounts: [.init(floatLiteral: 0)]), count: 4)
    var groupURL: URL? = nil
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
        dataStore.fetchTopReadEntryData { entry in
            let nextUpdate: Date
            let currentDate = Date()

            // Schedule an earlier refresh if this is placeholder content or not valid for today
            if entry.isPlaceholder || !(entry.date as NSDate).wmf_UTCDateIsTodayLocal() {
                let components = DateComponents(hour: 2)
                nextUpdate = Calendar.current.date(byAdding: components, to: currentDate) ?? currentDate
            } else {
                nextUpdate = currentDate.randomDateShortlyAfterMidnight() ?? currentDate
            }

            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    func getSnapshot(in context: Context, completion: @escaping (TopReadEntry) -> Void) {
        dataStore.fetchTopReadEntryData(usingCache: context.isPreview) { entry in
            completion(entry)
        }
    }

}

// MARK: - Views

struct TopReadView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.sizeCategory) private var sizeCategory

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
        .clearWidgetContainerBackground()
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
        let showSparkline = sizeCategory > .extraLarge ? false : (family == .systemLarge ? true : false)
        let rowCount = family == .systemLarge ? 4 : 2

        VStack(alignment: .leading, spacing: 8) {
            Text(TopReadWidget.LocalizedStrings.widgetTitle)
                .font(Font(WMFFont.for(.subheadline)))
                .fontWeight(.bold)
            ForEach(entry?.rankedElements.indices.prefix(rowCount) ?? 0..<0, id: \.self) { elementIndex in
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
                            .font(Font(WMFFont.for(.footnote)))
                            .foregroundColor(rankColor)
                    )
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 7))
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(entry?.rankedElements[index].title ?? "–")")
                        .font(Font(WMFFont.for(.mediumSubheadline)))
                        .foregroundColor(Color(.label))
                    if showSparkline {
                        Text("\(entry?.rankedElements[index].description ?? "–")")
                            .lineLimit(2)
                            .font(Font(WMFFont.for(.caption1)))
                            .foregroundColor(Color(.secondaryLabel))
                        Sparkline(style: .compactWithViewCount, timeSeries: entry?.rankedElements[index].viewCounts)
                            .cornerRadius(4)
                            .frame(height: proxy.size.height / 3.0, alignment: .leading)
                    } else {
                        Text("\(numberOfReadersTextOrEmptyForViewCount(entry?.rankedElements[index].viewCounts.last))")
                            .font(Font(WMFFont.for(.boldCaption1)))
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
                    .font(Font(WMFFont.for(.subheadline)))
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
                .font(Font(WMFFont.for(.boldCaption1)))
                .aspectRatio(contentMode: .fit)
                .foregroundColor(primaryTextColor)
                .readableShadow(intensity: isExpandedStyle ? 0 : 0.8)
            Text("\(rankedElement?.title ?? "–")")
                .lineLimit(nil)
                .font(Font(WMFFont.for(.headline)))
                .foregroundColor(primaryTextColor)
                .readableShadow(intensity: isExpandedStyle ? 0 : 0.8)
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
    }
}
