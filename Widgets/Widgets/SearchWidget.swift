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
        .configurationDisplayName(SearchWidget.LocalizedStrings.widgetTitle)
        .description(SearchWidget.LocalizedStrings.widgetDescription)
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
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
        switch widgetFamily {
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryRectangular:
            accessoryRectangularView
        case .accessoryInline:
            accessoryInlineView
        case .systemSmall:
            systemSmallView
        default:
            systemSmallView
        }
    }
    
    // MARK: - Widget Family Views
    
    @ViewBuilder
    private var systemSmallView: some View {
        if #available(iOS 17, *) {
            
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
            
        } else {
            
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
            .background(Color(theme.colors.paperBackground))
        }
    }
    
    @ViewBuilder
    private var accessoryCircularView: some View {
        ZStack {
            
            Image("W")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                
        }
        .widgetURL(entry.url)
    }
    
    @ViewBuilder
    private var accessoryRectangularView: some View {
        HStack(spacing: 8) {
            Image("W")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
            
            Text(SearchWidget.LocalizedStrings.searchWikipedia)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)

        }
        .widgetURL(entry.url)
    }
    
    @ViewBuilder
    private var accessoryInlineView: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
            
            Text(SearchWidget.LocalizedStrings.searchWikipedia)
                .font(.system(size: 13, weight: .medium))
        }
        .widgetURL(entry.url)
    }
}

// MARK: - Preview

struct SearchWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Home Screen Widget
            SearchWidgetView(entry: SearchEntry())
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, .light)
                .previewDisplayName("Home Screen - Light")
            
            SearchWidgetView(entry: SearchEntry())
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Home Screen - Dark")
            
            // Lock Screen Widgets
            SearchWidgetView(entry: SearchEntry())
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Lock Screen - Circular")
            
            SearchWidgetView(entry: SearchEntry())
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Lock Screen - Rectangular")
            
            SearchWidgetView(entry: SearchEntry())
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Lock Screen - Inline")
        }
    }
} 
