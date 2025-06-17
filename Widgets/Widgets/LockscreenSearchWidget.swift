import SwiftUI
import WidgetKit
import WMF
import WMFComponents

// MARK: - Widget

struct LockscreenSearchWidget: Widget {
    private let kind: String = WidgetController.SupportedWidget.lockscreenSearch.identifier
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockscreenSearchProvider(), content: { entry in
            LockscreenSearchWidgetView(entry: entry)
        })
        .configurationDisplayName(LockscreenSearchWidget.LocalizedStrings.widgetTitle)
        .description(LockscreenSearchWidget.LocalizedStrings.widgetDescription)
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

// MARK: - Timeline Entry

struct LockscreenSearchEntry: TimelineEntry {
    let date: Date
    let configuration: LockscreenSearchWidgetConfiguration
    let url: URL?
    
    init(date: Date = Date(), configuration: LockscreenSearchWidgetConfiguration = LockscreenSearchWidgetConfiguration()) {
        self.date = date
        self.configuration = configuration
        self.url = URL(string: "wikipedia://search")
    }
}

// MARK: - Configuration

struct LockscreenSearchWidgetConfiguration {
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

struct LockscreenSearchProvider: TimelineProvider {
    typealias Entry = LockscreenSearchEntry
    
    func placeholder(in context: Context) -> LockscreenSearchEntry {
        return LockscreenSearchEntry()
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LockscreenSearchEntry) -> Void) {
        let entry = LockscreenSearchEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LockscreenSearchEntry>) -> Void) {
        let entry = LockscreenSearchEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - View

struct LockscreenSearchWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entry: LockscreenSearchEntry
    
    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryRectangular:
            accessoryRectangularView
        case .accessoryInline:
            accessoryInlineView
        default:
            accessoryCircularView
        }
    }
    
    // MARK: - Widget Family Views
    
    var accessoryCircularView: some View {
        Image("W")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
            .widgetURL(entry.url)
    }
    
   var accessoryRectangularView: some View {
        HStack(spacing: 8) {
            Image("W")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
            
            Text(LockscreenSearchWidget.LocalizedStrings.searchWikipedia)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
        }
        .widgetURL(entry.url)
    }
    

   var accessoryInlineView: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
            
            Text(LockscreenSearchWidget.LocalizedStrings.searchWikipedia)
                .font(.system(size: 13, weight: .medium))
        }
        .widgetURL(entry.url)
    }
} 
