import WMFComponents
import SwiftUI
import WMF

struct TalkPageArchivesView: View {
    
    @EnvironmentObject var observableTheme: ObservableTheme
    @EnvironmentObject var data: ShiftingTopViewsData
    
    // This will trigger body() again upon dynamic type size change, so that font sizes can scale up
    @Environment(\.sizeCategory) var sizeCategory: ContentSizeCategory
    
    private let pageTitle: String
    private let fetcher: TalkPageArchivesFetcher
    
    @SwiftUI.State private var firstPageFetchTask: Task<Void, Never>?
    @SwiftUI.State private var nextPageFetchTask: Task<Void, Never>?
    @SwiftUI.State private var didFetchFirstPage = false
    @SwiftUI.State private var items: [TalkPageArchivesItem] = []
    @SwiftUI.State private var firstPageFetchError: Error? = nil
    
    let didTapItem: (TalkPageArchivesItem) -> Void
    
    init(pageTitle: String, siteURL: URL, didTapItem: @escaping (TalkPageArchivesItem) -> Void) {
        self.pageTitle = pageTitle
        self.didTapItem = didTapItem
        self.fetcher = TalkPageArchivesFetcher(siteURL: siteURL, pageTitle: pageTitle)
    }
    
    var body: some View {
        ShiftingScrollView {
            
            if items.isEmpty && didFetchFirstPage && firstPageFetchError == nil {
                TalkPageArchivesInfoText(info: WMFLocalizedString("talk-pages-archives-empty-title", value: "No archived pages found.", comment: "Text displayed when no talk page archive pages were found."))
            } else if !items.isEmpty {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(items) { item in
                        DisclosureButton(item: item, action: didTapItem)
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
                TalkPageArchivesInfoText(info: CommonStrings.genericErrorDescription)
            }
        }
        .background(Color(observableTheme.theme.colors.paperBackground))
        .onAppear {
            guard !didFetchFirstPage else {
                return
            }

            firstPageFetchTask = Task(priority: .userInitiated) {
                data.isLoading = true
                do {
                    let response = try await fetcher.fetchFirstPage()
                    data.isLoading = false
                    didFetchFirstPage = true
                    self.items = processResponse(response)
                } catch {
                    data.isLoading = false
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
        return WMFFont.for(.boldCallout)
    }
    
    private func itemIsLast(_ item: TalkPageArchivesItem) -> Bool {
        return items.firstIndex(of: item) == items.count - 1
    }
    
    private func processResponse(_ response: TalkPageArchivesFetcher.APIResponse) -> [TalkPageArchivesItem] {
        let items = response.query?.pages?.compactMap {  TalkPageArchivesItem(pageID: $0.pageID, title: $0.title, displayTitle: $0.displayTitle) } ?? []
        return items.filter { $0.title != pageTitle && !self.items.contains($0) }
    }
}

// MARK: Subviews

private struct TalkPageArchivesInfoText: View {
    
    @EnvironmentObject var observableTheme: ObservableTheme
    @Environment(\.sizeCategory) var sizeCategory: ContentSizeCategory
    let info: String

    var body: some View {
        Text(info)
            .multilineTextAlignment(.center)
            .font(Font(infoFont))
            .foregroundColor(Color(observableTheme.theme.colors.secondaryText))
            .padding(EdgeInsets(top: 30, leading: 16, bottom: 30, trailing: 16))
    }
    
    private var infoFont: UIFont {
        return WMFFont.for(.callout)
    }
}
