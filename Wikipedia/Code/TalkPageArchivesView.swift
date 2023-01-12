import SwiftUI
import WMF

struct TalkPageArchivesView: View {
    
    @EnvironmentObject var observableTheme: ObservableTheme
    
    // This will trigger body() again upon dynamic type size change, so that font sizes can scale up
    @Environment(\.sizeCategory) var sizeCategory: ContentSizeCategory
    
    private let pageTitle: String
    private let fetcher: TalkPageArchivesFetcher
    
    @SwiftUI.State private var firstPageFetchTask: Task<Void, Never>?
    @SwiftUI.State private var nextPageFetchTask: Task<Void, Never>?
    @SwiftUI.State private var didFetchFirstPage = false
    @SwiftUI.State private var items: [TalkPageArchivesItem] = []
    @SwiftUI.State private var firstPageFetchError: Error? = nil
    
    init(pageTitle: String, siteURL: URL) {
        self.pageTitle = pageTitle
        self.fetcher = TalkPageArchivesFetcher(siteURL: siteURL, pageTitle: pageTitle)
    }
    
    var body: some View {
        ShiftingScrollView {
            
            if items.isEmpty && didFetchFirstPage && firstPageFetchError == nil {
               Text(WMFLocalizedString("talk-pages-archives-empty-title", value: "No archived pages found.", comment: "Text displayed when no talk page archive pages were found."))
                   .font(Font(infoFont))
                   .foregroundColor(Color(observableTheme.theme.colors.secondaryText))
                   .padding(EdgeInsets(top: 30, leading: 16, bottom: 30, trailing: 16))
            } else if !items.isEmpty {
                LazyVStack {
                    ForEach(items) { item in
                        Text("\(item.displayTitle)")
                            .foregroundColor(Color(observableTheme.theme.colors.primaryText))
                            .font(Font(itemFont))
                            .onAppear {
                                if itemIsLast(item) {
                                    nextPageFetchTask?.cancel()
                                    nextPageFetchTask = Task(priority: .userInitiated) {
                                        do {
                                            if let response = try await fetcher.fetchNextPage() {
                                                let items = processResponse(response)
                                                self.items.append(contentsOf: items)
                                            }
                                        } catch {
                                            let userInfo = [Notification.Name.showErrorBannerNSErrorKey: error]
                                            NotificationCenter.default.post(name: .showErrorBanner, object: nil, userInfo: userInfo)
                                        }
                                    }
                                }
                            }
                    }
                }
            } else if firstPageFetchError != nil {
                Text(CommonStrings.genericErrorDescription)
                    .font(Font(infoFont))
                    .foregroundColor(Color(observableTheme.theme.colors.secondaryText))
                    .padding(EdgeInsets(top: 30, leading: 16, bottom: 30, trailing: 16))
            }
        }
        .background(Color(observableTheme.theme.colors.paperBackground))
        .onAppear {
            guard !didFetchFirstPage else {
                return
            }

            firstPageFetchTask = Task(priority: .userInitiated) {
                do {
                    let response = try await fetcher.fetchFirstPage()
                    didFetchFirstPage = true
                    self.items = processResponse(response)
                } catch {
                    didFetchFirstPage = true
                    self.firstPageFetchError = error
                    let userInfo = [Notification.Name.showErrorBannerNSErrorKey: error]
                    NotificationCenter.default.post(name: .showErrorBanner, object: nil, userInfo: userInfo)
                }
            }
        }
        .onDisappear {
            firstPageFetchTask?.cancel()
            nextPageFetchTask?.cancel()
            firstPageFetchTask = nil
            nextPageFetchTask = nil
        }
    }
    
    // MARK: Private Helpers
    
    private var itemFont: UIFont {
        return UIFont.wmf_scaledSystemFont(forTextStyle: .callout, weight: .semibold, size: 16)
    }
    
    private var infoFont: UIFont {
        return UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 17)
    }
    
    private func itemIsLast(_ item: TalkPageArchivesItem) -> Bool {
        return items.firstIndex(of: item) == items.count - 1
    }
    
    private func processResponse(_ response: TalkPageArchivesFetcher.APIResponse) -> [TalkPageArchivesItem] {
        let items = response.query?.pages?.compactMap {  TalkPageArchivesItem(pageID: $0.pageID, title: $0.title, displayTitle: $0.displayTitle) } ?? []
        return items.filter { $0.title != pageTitle }
    }
}
