import Foundation
import WMF
import WMFData

/// Searches articles and files for the legacy search screens.
///
/// The fetcher uses `WMFArticleSearchDataController` and converts the result into `WMFSearchResults`.
/// Remove this class when the legacy search screens move to WMFComponents.
final class WMFSearchFetcher {

    private let dataController: WMFArticleSearchDataController
    private let lock = NSLock()
    private var tasks: [UUID: Task<Void, Never>] = [:]

    init(dataController: WMFArticleSearchDataController = .shared) {
        self.dataController = dataController
    }

    /// Search article titles by prefix.
    func fetchArticles(forSearchTerm searchTerm: String, siteURL: URL, resultLimit: UInt, failure: @escaping (Error) -> Void, success: @escaping (WMFSearchResults) -> Void) {
        fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, fullTextSearch: false, appendToPreviousResults: nil, failure: failure, success: success)
    }

    /// Search articles by prefix or by full text.
    /// - Parameter previousResults: When present, the new results are merged into this object and the object is returned.
    func fetchArticles(forSearchTerm searchTerm: String, siteURL: URL, resultLimit: UInt, fullTextSearch: Bool, appendToPreviousResults previousResults: WMFSearchResults?, failure: @escaping (Error) -> Void, success: @escaping (WMFSearchResults) -> Void) {
        guard let project = WikimediaProject(siteURL: siteURL)?.wmfProject else {
            failure(RequestError.invalidParameters)
            return
        }
        search(term: searchTerm, project: project, namespace: 0, languageVariantCode: siteURL.wmf_languageVariantCode, resultLimit: resultLimit, fullTextSearch: fullTextSearch, previousResults: previousResults, failure: failure, success: success)
    }

    /// Search files on Wikimedia Commons.
    func fetchFiles(forSearchTerm searchTerm: String, resultLimit: UInt, fullTextSearch: Bool, appendToPreviousResults previousResults: WMFSearchResults?, failure: @escaping (Error) -> Void, success: @escaping (WMFSearchResults) -> Void) {
        search(term: searchTerm, project: .commons, namespace: 6, languageVariantCode: nil, resultLimit: resultLimit, fullTextSearch: fullTextSearch, previousResults: previousResults, failure: failure, success: success)
    }

    /// Cancel every request that is in progress. Each cancelled request calls its failure block with a cancellation error.
    func cancelAllFetches() {
        lock.lock()
        let running = tasks.values
        tasks.removeAll()
        lock.unlock()
        running.forEach { $0.cancel() }
    }

    // MARK: - Private

    private func search(term: String, project: WMFProject, namespace: Int, languageVariantCode: String?, resultLimit: UInt, fullTextSearch: Bool, previousResults: WMFSearchResults?, failure: @escaping (Error) -> Void, success: @escaping (WMFSearchResults) -> Void) {
        let limit = Int(min(resultLimit, WMFMaxSearchResultLimit))
        let dataController = self.dataController
        let identifier = UUID()

        let task = Task { [weak self] in
            defer {
                self?.forget(identifier)
            }
            do {
                let response = try await dataController.searchPages(term: term, project: project, namespace: namespace, limit: limit, fullText: fullTextSearch)
                guard !Task.isCancelled else {
                    failure(URLError(.cancelled))
                    return
                }
                let results = WMFSearchResults(searchTerm: term, response: response, languageVariantCode: languageVariantCode)
                guard let previousResults else {
                    success(results)
                    return
                }
                previousResults.merge(results)
                success(previousResults)
            } catch {
                failure(Task.isCancelled ? URLError(.cancelled) : error)
            }
        }

        lock.lock()
        tasks[identifier] = task
        lock.unlock()
    }

    private func forget(_ identifier: UUID) {
        lock.lock()
        tasks[identifier] = nil
        lock.unlock()
    }
}
