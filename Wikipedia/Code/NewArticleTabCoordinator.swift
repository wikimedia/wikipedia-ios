import UIKit
import WMF
import WMFComponents

final class NewArticleTabCoordinator: Coordinator {
    var navigationController: UINavigationController
    var dataStore: MWKDataStore
    var theme: Theme


    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
    }

    var seed: WMFArticle?
    var related: [WMFArticle?] = []

    private let contentSource = WMFRelatedPagesContentSource()

    func loadNextBatch(
        completion: @escaping (_ seed: WMFArticle?, _ related: [WMFArticle?]) -> Void
    ) {
        let moc = dataStore.feedImportContext

        contentSource.loadNewContent(in: moc, force: true) {
            moc.perform {
                let groupFetch: NSFetchRequest<WMFContentGroup> = WMFContentGroup.fetchRequest()
                groupFetch.predicate = NSPredicate(
                    format: "contentGroupKindInteger == %d",
                    WMFContentGroupKind.relatedPages.rawValue
                )
                groupFetch.sortDescriptors = [ .init(key: "date", ascending: false) ]
                groupFetch.fetchLimit = 1

                guard let group = (try? moc.fetch(groupFetch))?.first else {
                    DispatchQueue.main.async {
                        self.seed = nil
                        self.related = []
                    }
                    return
                }

                if let seedURL = group.articleURL {
                    let seedKey = seedURL.wmf_databaseKey ?? ""
                    let seedReq: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
                    seedReq.predicate = NSPredicate(format: "key == %@", seedKey)
                    seedReq.fetchLimit = 1
                    let seedArticle = (try? moc.fetch(seedReq))?.first

                    let urls = (group.fullContent?.object as? [URL]) ?? []

                    let relatedKeys = urls.compactMap { $0.wmf_databaseKey }
                    let relatedReq: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
                    relatedReq.predicate = NSPredicate(format: "key IN %@", relatedKeys)

                    let fetched = (try? moc.fetch(relatedReq)) ?? []
                    let byKey = [String: WMFArticle?](
                        uniqueKeysWithValues: fetched.compactMap { art in
                            guard let k = art.key else { return (String(), nil) }
                            return (k, art)
                        }
                    )
                    let relatedArticles = relatedKeys.compactMap { byKey[$0] }

                    DispatchQueue.main.async {

                        completion(seedArticle, relatedArticles)
                    }
                }
            }
        }
    }

    @discardableResult
    func start() -> Bool {


        loadNextBatch { seed, related in
            print("====== SEED: \(seed?.displayTitle), RELATED: \(related)")
            self.seed = seed
            self.related = related
        }

        let viewModel = WMFNewArticleTabViewModel(title: CommonStrings.newTab)
        let viewController = WMFNewArticleTabController(dataStore: dataStore, theme: theme, viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
        return true
    }

}
