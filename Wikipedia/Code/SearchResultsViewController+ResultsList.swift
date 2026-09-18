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
            viewOnMapActionTitle: CommonStrings.viewOnMapTitle,
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
                ArticleTabsFunnel.shared.logLongPressOpen()
                self?.articleTappedAction?(result.articleURL, false)
            },
            openInNewTabAction: { [weak self] result, _ in
                WMFArticleTabsDataController.shared.didTapOpenNewTab()
                ArticleTabsFunnel.shared.logLongPressOpenInNewTab()
                self?.articleTappedAction?(result.articleURL, true)
            },
            openInBackgroundTabAction: { [weak self] result, _ in
                self?.openInBackgroundTab(result)
            },
            openOnMapAction: { result, _ in
                let placesURL = NSUserActivity.wmf_URLForActivity(of: .places, withArticleURL: result.articleURL)
                UIApplication.shared.open(placesURL)
            },
            saveOrUnsaveAction: { [weak self] result, index, source in
                if source == .contextMenu {
                    ArticleTabsFunnel.shared.logLongPressSave()
                }
                self?.saveOrUnsave(result, at: index)
            },
            shareAction: { [weak self] result, _, frame, source in
                if source == .contextMenu {
                    ArticleTabsFunnel.shared.logLongPressShare()
                }
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
        updateEntryPoint(query: searchResults.searchTerm, languageCode: siteURL.wmf_languageCode)
    }

    // MARK: - Semantic search entry point

    private func updateEntryPoint(query: String?, languageCode: String?) {
        guard let query, !query.isEmpty, let languageCode else {
            resultsViewModel.hideEntryPoint()
            return
        }
        let dataController = WMFSemanticSearchDataController.shared

        do {
            try dataController.assignExperimentIfNeeded(languageCode: languageCode)
        } catch {
            DDLogError("Semantic search experiment assignment failed: \(error)")
        }
        guard dataController.isEntryPointAvailable(languageCode: languageCode) else {
            resultsViewModel.hideEntryPoint()
            return
        }
        if let entryPointViewModel = resultsViewModel.entryPointViewModel, entryPointViewModel.languageCode == languageCode {
            entryPointViewModel.update(query: query)
        } else {
            resultsViewModel.showEntryPoint(makeEntryPointViewModel(query: query, languageCode: languageCode))
        }
    }

    func hideEntryPointIfLanguageChanged(for siteURL: URL) {
        guard let entryPointViewModel = resultsViewModel.entryPointViewModel,
              entryPointViewModel.languageCode != siteURL.wmf_languageCode else {
            return
        }
        resultsViewModel.hideEntryPoint()
    }

    private func makeEntryPointViewModel(query: String, languageCode: String) -> WMFSemanticSearchEntryPointViewModel {
        let dataController = WMFSemanticSearchDataController.shared
        let showsTryItNow = !dataController.hasUsedEntryPoint
        if showsTryItNow {
            do {
                try dataController.markEntryPointUsed()
            } catch {
                DDLogError("Marking the semantic search entry point as used failed: \(error)")
            }
        }
        return WMFSemanticSearchEntryPointViewModel(
            query: query,
            languageCode: languageCode,
            showsTryItNow: showsTryItNow,
            tapAction: { _ in },
            infoAction: { _ in },
            hideAction: { [weak self] _ in
                self?.hideEntryPoint()
            }
        )
    }

    private func hideEntryPoint() {
        do {
            try WMFSemanticSearchDataController.shared.setEntryPointHidden(true)
        } catch {
            DDLogError("Hiding the semantic search entry point failed: \(error)")
        }
        resultsViewModel.hideEntryPoint()
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
        let sourceRect = frame.map { view.convert($0, from: nil) }
        _ = share(article: article(for: result), articleURL: result.articleURL, dataStore: dataStore, theme: theme, eventLoggingCategory: .search, eventLoggingLabel: nil, sourceView: view, sourceRect: sourceRect)
    }
}
