import SwiftUI
import WidgetKit
import WMF
import WMFComponents

// MARK: - Widget

struct SearchWidget: Widget {
    private let kind: String = WidgetController.SupportedWidget.search.identifier
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SearchProvider(), content: { entry in
            SearchWidgetView(entry: entry)
        })
        .configurationDisplayName(CommonStrings.searchTitle)
        .description(SearchWidget.LocalizedStrings.widgetDescription)
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

// MARK: - Timeline Entry

struct SearchEntry: TimelineEntry {
    let date: Date
    let configuration: SearchWidgetConfiguration
    let url: URL?
    
    init(date: Date = Date(), configuration: SearchWidgetConfiguration = SearchWidgetConfiguration()) {
        self.date = date
        self.configuration = configuration
        self.url = URL(string: "wikipedia://search")
    }
}

// MARK: - Configuration

struct SearchWidgetConfiguration {
    let languageCode: String
    let siteURL: URL
    
    init() {
        let sharedCache = SharedContainerCache(fileName: SharedContainerCacheCommonNames.widgetCache)
        let cache = sharedCache.loadCache() ?? WidgetCache(settings: .default, featuredContent: nil)
        self.languageCode = cache.settings.languageCode
        self.siteURL = cache.settings.siteURL
    }
}

// MARK: - Timeline Provider

struct SearchProvider: TimelineProvider {
    typealias Entry = SearchEntry
    
    func placeholder(in context: Context) -> SearchEntry {
        return SearchEntry()
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SearchEntry) -> Void) {
        let entry = SearchEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SearchEntry>) -> Void) {
        let entry = SearchEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - View

struct SearchWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.colorScheme) private var colorScheme
    
    var entry: SearchEntry
    
    private var theme: Theme {
        return colorScheme == .dark ? Theme.widgetDark : Theme.widgetLight
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image("wikipedia-globe")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .padding(.bottom, 8)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(Color(theme.colors.secondaryText))

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(theme.colors.searchFieldBackground))
            .cornerRadius(8)

        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(entry.url)
        .containerBackground(Color(theme.colors.paperBackground), for: .widget)
    }
}

// MARK: - Preview

struct SearchWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SearchWidgetView(entry: SearchEntry())
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, .light)
                .previewDisplayName("Light Mode")
            
            SearchWidgetView(entry: SearchEntry())
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode")
        }
    }
} 
