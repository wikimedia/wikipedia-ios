import Foundation

@MainActor
class TalkPageArchivesViewModel: ObservableObject {
    
    struct Item {
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
    
    private let fetcher = TalkPageArchivesFetcher()
    
    @Published var isLoading: Bool = false
    @Published var items: [Item] = []
    @Published var error: Error? = nil
    
    private let pageTitle: String
    let siteURL: URL
    
    init(pageTitle: String, siteURL: URL) {
        self.pageTitle = pageTitle
        self.siteURL = siteURL
    }
    
    func fetchArchives() async {
        isLoading = true
        do {
            let response = try await fetcher.fetchArchives(pageTitle: pageTitle, siteURL: siteURL)
            isLoading = false
            self.items = response.query?.pages?.compactMap {  Item(title: $0.title, displayTitle: $0.displaytitle, pageID: $0.pageid) } ?? []
        } catch {
            isLoading = false
            self.error = error
        }
    }
}
