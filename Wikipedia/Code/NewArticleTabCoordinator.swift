import UIKit
import WMF
import WMFComponents

final class NewArticleTabCoordinator: Coordinator {
    var navigationController: UINavigationController
    var dataStore: MWKDataStore
    var theme: Theme
    var dykFetcher: WMFFeedDidYouKnowFetcher
    private let sharedCache = SharedContainerCache(fileName: SharedContainerCacheCommonNames.dykCache)
    public var dykFacts: [WMFFeedDidYouKnow]? = nil

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        dykFetcher = WMFFeedDidYouKnowFetcher()
    }

    @discardableResult
    func start() -> Bool {
        
        let tappedURLAction: ((URL?) -> Void) = { url in
            guard let url else { return }
            
            let linkCoordinator = LinkCoordinator(navigationController: self.navigationController, url: url, dataStore: self.dataStore, theme: self.theme, articleSource: .undefined)
            linkCoordinator.start()
        }
        
        let viewModel = WMFNewArticleTabViewModel(
            text: "Placeholder",
            title: CommonStrings.newTab,
            languageCode: dataStore.languageLinkController.appLanguage?.languageCode,
            dykLocalizedStrings: WMFNewArticleTabViewModel.DYKLocalizedStrings.init(dyk: dyk, fromSource: fromLanguageWikipediaTextFor(languageCode: dataStore.languageLinkController.appLanguage?.languageCode)),
            fromSourceDefault: fromWikipediaDefault, tappedURLAction: tappedURLAction)
        let viewController = WMFNewArticleTabController(dataStore: dataStore, theme: theme, viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)

        fetchDYK { facts in
            DispatchQueue.main.async {
                viewModel.facts = facts?.map { $0.html }
                viewModel.isLoading = false
            }
        }

        return true
    }
    
    // MARK: - DYK
    
    let fromLanguageWikipedia = WMFLocalizedString("new-article-tab-from-language-wikipedia", value: "from %1$@ Wikipedia", comment: "Text displayed as Wikipedia source on new tab. %1$@ will be replaced with the language.")
    let fromWikipediaDefault = WMFLocalizedString("new-article-tab-from-wikipedia-default", value: "from Wikipedia", comment: "Text displayed as Wikipedia source on new tab if language is unavailable.")
    let dyk = WMFLocalizedString("did-you-know", value: "Did you know", comment: "Text displayed as heading for section of new tab dedicated to DYK")
    
    private func fromLanguageWikipediaTextFor(languageCode: String?) -> String {
        guard let languageCode = languageCode, let localizedLanguageString = Locale.current.localizedString(forLanguageCode: languageCode) else {
            return fromWikipediaDefault
        }

        return String.localizedStringWithFormat(fromLanguageWikipedia, localizedLanguageString)
    }
    
    private func fetchDYK(completion: @escaping ([WMFFeedDidYouKnow]?) -> Void) {
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode else {
            return
        }
        guard let url = URL(string: "https://\(languageCode).wikipedia.org") else {
            completion(nil)
            return
        }

        dykFetcher.fetchDidYouKnow(withSiteURL: url) { [weak self] error, facts in
            guard error == nil else {
                completion(nil)
                return
            }
            self?.dykFacts = facts
            completion(facts)
        }
    }
}
