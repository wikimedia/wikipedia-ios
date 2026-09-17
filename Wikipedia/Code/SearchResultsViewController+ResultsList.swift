import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import CocoaLumberjackSwift

extension SearchResultsViewController {

    typealias SearchResult = WMFSearchResultsViewModel.SearchResult

    private static let noSearchResultsMessage = WMFLocalizedString("empty-no-search-results-message", value: "No results found", comment: "Shown when there are no search results")

    func makeResultsViewModel() -> WMFSearchResultsViewModel {
        let localizedStrings = WMFSearchResultsViewModel.LocalizedStrings(
            openActionTitle: CommonStrings.articleTabsOpen,
            openInNewTabActionTitle: CommonStrings.articleTabsOpenInNewTab,
            openInBackgroundTabActionTitle: CommonStrings.articleTabsOpenInBackgroundTab,
            saveActionTitle: CommonStrings.saveTitle,
            unsaveActionTitle: CommonStrings.unsaveTitle,
            shareActionTitle: CommonStrings.shareMenuTitle,
            noResultsMessage: Self.noSearchResultsMessage,
            noInternetConnectionTitle: CommonStrings.noInternetConnection)

        return WMFSearchResultsViewModel(
            localizedStrings: localizedStrings,
            noInternetConnectionImage: UIImage(named: "no-internet-blank"),
            isSavedAction: { [weak self] result in
                self?.dataStore.savedPageList.isAnyVariantSaved(result.articleURL) ?? false
            },
            tapAction: { [weak self] result, index in
                guard let self else { return }
                SearchFunnel.shared.logSearchResultTap(position: index, source: source.stringValue)
                saveLastSearch()
                articleTappedAction?(result.articleURL, false)
            },
            openAction: { [weak self] result, _ in
                self?.articleTappedAction?(result.articleURL, false)
            },
            openInNewTabAction: { [weak self] result, _ in
                self?.articleTappedAction?(result.articleURL, true)
            },
            openInBackgroundTabAction: { [weak self] result, _ in
                self?.openInBackgroundTab(result)
            },
            saveOrUnsaveAction: { [weak self] result, index in
                self?.saveOrUnsave(result, at: index)
            },
            shareAction: { [weak self] result, _, frame in
                self?.share(result, frame: frame)
            })
    }

    // MARK: - Results

    func displaySearchResults(_ searchResults: WMFSearchResults, siteURL: URL) {
        displayedSearchTerm = searchResults.searchTerm
        displayedSiteURL = siteURL
        let mapper = SearchResultsMapper(siteURL: siteURL, redirectMappings: searchResults.redirectMappings ?? [])

        var searchResultsByArticleURL: [String: MWKSearchResult] = [:]
        let results = (searchResults.results ?? []).compactMap { mwkResult -> SearchResult? in
            guard let result = mapper.searchResult(from: mwkResult) else {
                return nil
            }
            searchResultsByArticleURL[result.id] = mwkResult
            return result
        }
        self.searchResultsByArticleURL = searchResultsByArticleURL

        resultsViewModel.showResults(results, searchTerm: searchResults.searchTerm, project: mapper.project)
    }

    private func openInBackgroundTab(_ result: SearchResult) {
        guard let project = SearchResultsMapper.project(for: result.articleURL), let title = result.articleURL.wmf_title else { return }
        let tabsDataController = WMFArticleTabsDataController.shared
        let article = WMFArticleTabsDataController.WMFArticle(identifier: nil, title: title, project: project, articleURL: result.articleURL)
        Task {
            do {
                tabsDataController.didTapOpenNewTab()
                let tabsMax = tabsDataController.tabsMax
                guard try await tabsDataController.tabsCount() < tabsMax else {
                    if let currentTabIdentifier = try await tabsDataController.currentTabIdentifier() {
                        _ = try await tabsDataController.appendArticle(article, toTabIdentifier: currentTabIdentifier)
                    } else {
                        _ = try await tabsDataController.createArticleTab(initialArticle: article)
                    }
                    WMFToastManager.sharedInstance.showRichToast(String.localizedStringWithFormat(CommonStrings.articleTabsLimitToastFormat, tabsMax), subtitle: nil, image: WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangleFill), duration: 10, dismissPreviousToasts: true)
                    return
                }
                _ = try await tabsDataController.createArticleTab(initialArticle: article, setAsCurrent: false)
                ArticleTabsFunnel.shared.logLongPressOpenInBackgroundTab()
            } catch {
                DDLogError("Failed to create background tab: \(error)")
            }
        }
    }

    func displaySearchError(_ error: Error) {
        searchResultsByArticleURL = [:]
        let error = error as NSError
        if error.wmf_isNetworkConnectionError() {
            resultsViewModel.showEmptyState(.noInternetConnection)
        } else if error.wmf_isCancelledError() {
            resultsViewModel.reset()
        } else {
            resultsViewModel.showEmptyState(.noResults)
        }
    }

    // MARK: - Saved state

    @objc func articleWasUpdated(_ notification: Notification) {
        guard let updatedArticle = notification.object as? WMFArticle,
              updatedArticle.hasChangedValuesForCurrentEventThatAffectSavedState else {
            return
        }
        resultsViewModel.refreshSavedStates()
    }

    private func article(for result: SearchResult) -> WMFArticle? {
        let article = dataStore.fetchOrCreateArticle(with: result.articleURL)
        article?.update(with: searchResultsByArticleURL[result.id])
        return article
    }

    private func saveOrUnsave(_ result: SearchResult, at index: Int) {
        if dataStore.savedPageList.isAnyVariantSaved(result.articleURL) {
            guard let article = article(for: result) else { return }
            let cancel = ReadingListsAlertActionType.cancel.action()
            let unsave = ReadingListsAlertActionType.unsave.action { [weak self] in
                self?.unsave(result, at: index)
            }
            ReadingListsAlertController().showAlertIfNeeded(presenter: self, for: [article], with: [cancel, unsave]) { [weak self] showed in
                if !showed {
                    self?.unsave(result, at: index)
                }
            }
        } else {
            dataStore.savedPageList.addSavedPage(with: result.articleURL)
            UIAccessibility.post(notification: .announcement, argument: CommonStrings.accessibilitySavedNotification)
            ReadingListsFunnel.shared.logSave(category: .search, label: nil, articleURL: result.articleURL, date: nil, measurePosition: index)
        }
    }

    private func unsave(_ result: SearchResult, at index: Int) {
        dataStore.savedPageList.removeEntry(with: result.articleURL)
        UIAccessibility.post(notification: .announcement, argument: CommonStrings.accessibilityUnsavedNotification)
        ReadingListsFunnel.shared.logUnsave(category: .search, label: nil, articleURL: result.articleURL, date: nil, measurePosition: index)
    }

    // MARK: - Share

    private func share(_ result: SearchResult, frame: CGRect?) {
        let sourceView = UIView(frame: frame ?? .zero)
        _ = share(article: article(for: result), articleURL: result.articleURL, dataStore: dataStore, theme: theme, eventLoggingCategory: .search, eventLoggingLabel: nil, sourceView: sourceView)
    }
}
