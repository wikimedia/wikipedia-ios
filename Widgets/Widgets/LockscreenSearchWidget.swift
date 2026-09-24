import SwiftUI
import WidgetKit
import WMF
import WMFComponents
import WMFNativeLocalizations

// MARK: - Widget

struct LockscreenSearchWidget: Widget {
    private let kind: String = WidgetController.SupportedWidget.lockscreenSearch.identifier
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockscreenSearchProvider(), content: { entry in
            LockscreenSearchWidgetView(entry: entry)
        })
        .configurationDisplayName(CommonStrings.searchTitle)
        .description(CommonStrings.lockscreenSearchWidgetDescription)
        .supportedFamilies([.accessoryCircular])
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
        // Include source query parameter so the app knows this came from a widget
        self.url = URL(string: "wikipedia://search?source=widget_lockscreen_search")
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
        let timeline = Timeline(entries: [entry], policy: .after(WidgetController.searchWidgetNextReloadDate))
        Task {
            await WidgetController.submitSearchWidgetHeartbeat(actionSource: "widget_lockscreen_search")
            completion(timeline)
        }
    }
}

// MARK: - View

struct LockscreenSearchWidgetView: View {
    var entry: LockscreenSearchEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image("W")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
        }
        .widgetURL(entry.url)
        .modifier(ContainerBackgroundModifier())
    }

}

// MARK: - Container Background Modifier

struct ContainerBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.containerBackground(Color.clear, for: .widget)
    }
}
