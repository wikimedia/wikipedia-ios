import SwiftUI

struct TalkPageArchivesItem {
    let title: String
    let displayTitle: String
    let pageID: Int
    
    init?(title: String?, displayTitle: String?, pageID: Int?) {
        guard let title = title,
              let displayTitle = displayTitle,
            let pageID = pageID else {
            return nil
        }
        
        self.title = title
        self.displayTitle = displayTitle
        self.pageID = pageID
    }
}

struct TalkPageArchivesView: View {
    
    @SwiftUI.State private var task: Task<Void, Never>?
    @SwiftUI.State private var items: [TalkPageArchivesItem] = []
    @SwiftUI.State private var error: Error? = nil
    @EnvironmentObject var data: CustomNavigationViewData
    @EnvironmentObject var observableTheme: ObservableTheme
    
    private let pageTitle: String
    private let siteURL: URL
    private let fetcher = TalkPageArchivesFetcher()
    
    var didTapItem: (TalkPageArchivesItem) -> Void = { _ in }
    
    init(pageTitle: String, siteURL: URL) {
        self.pageTitle = pageTitle
        self.siteURL = siteURL
    }
    
    var body: some View {
        TrackingScrollView(
            axes: [.vertical],
            showsIndicators: true
        ) {
            LazyVStack(alignment: .leading) {
                ForEach(items, id: \.pageID) { item in
                    Text(item.displayTitle)
                        .background(observableTheme.theme.isDark ? Color.blue : Color.red)
                        .onTapGesture {
                            didTapItem(item)
                        }
                }
            }
        }
        .onAppear {
            task = Task(priority: .userInitiated) {
                data.isLoading = true
                do {
                    let response = try await fetcher.fetchArchives(pageTitle: pageTitle, siteURL: siteURL)
                    data.isLoading = false
                    self.items = response.query?.pages?.compactMap {  TalkPageArchivesItem(title: $0.title, displayTitle: $0.displaytitle, pageID: $0.pageid) } ?? []
                } catch {
                    data.isLoading = false
                    self.error = error
                }
            }
        }
        .onDisappear {
            task?.cancel()
            task = nil
        }
    }
}
