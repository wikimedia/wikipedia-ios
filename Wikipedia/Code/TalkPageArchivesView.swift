import SwiftUI
import WMF

struct TalkPageArchivesView: View {
    
    @EnvironmentObject var observableTheme: ObservableTheme
    
    private let pageTitle: String
    private let siteURL: URL
    private let fetcher = TalkPageArchivesFetcher()
    
    @SwiftUI.State private var task: Task<Void, Never>?
    @SwiftUI.State private var didFetchInitial = false
    @SwiftUI.State private var items: [TalkPageArchivesItem] = []
    
    init(pageTitle: String, siteURL: URL) {
        self.pageTitle = pageTitle
        self.siteURL = siteURL
    }
    
    var body: some View {
        ShiftingScrollView {
            LazyVStack {
                ForEach(items, id: \.pageID) { item in
                    Text("\(item.displayTitle)")
                        .foregroundColor(Color(observableTheme.theme.colors.primaryText))
               }
            }
        }
        .background(Color(observableTheme.theme.colors.paperBackground))
        .onAppear {
            guard !didFetchInitial else {
                return
            }

            task = Task(priority: .userInitiated) {
                do {
                    let response = try await fetcher.fetchArchives(pageTitle: pageTitle, siteURL: siteURL)
                    didFetchInitial = true
                    let items = response.query?.pages?.compactMap {  TalkPageArchivesItem(pageID: $0.pageID, title: $0.title, displayTitle: $0.displayTitle) } ?? []
                    self.items = items.filter { $0.title != pageTitle }
                } catch {
                    didFetchInitial = true
                }
            }
        }
        .onDisappear {
            task?.cancel()
            task = nil
        }
    }
}
