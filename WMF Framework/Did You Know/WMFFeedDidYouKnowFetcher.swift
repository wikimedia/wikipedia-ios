import WMFData

public final class WMFFeedDidYouKnowFetcher: Fetcher {
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore

    public func fetchDidYouKnow(withSiteURL siteURL: URL, completion: @escaping (Error?, [WMFDidYouKnow]?) -> Void) {

        let sharedCache = SharedContainerCache.init(fileName: self.cachedFileName(for: siteURL), subdirectoryPathComponent: SharedContainerCacheCommonNames.didYouKnowCache)
        var cache = sharedCache.loadCache() ?? DidYouKnowCache(didYouKnowItems: [])

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let stringToday = today.formatted()
        let key = "dyk-last-fetch-date"

        let lastChecked = try? userDefaultsStore?.load(key: key) ?? ""

        let wasCheckedToday = stringToday == lastChecked

        let pathComponents = ["feed", "did-you-know"]

        let facts = cache.didYouKnowItems

        if wasCheckedToday, let facts = facts, !facts.isEmpty {
            completion(nil, facts)
            return
        }

        guard let taskURL = configuration.feedContentAPIURLForURL(siteURL, appending: pathComponents) else {
            completion(Fetcher.invalidParametersError, nil)
            return
        }

        session.jsonDecodableTask(with: taskURL) { (facts: [WMFDidYouKnow]?, response, error) in

            if let error = error {
                completion(error, cache.didYouKnowItems)
                return
            }
            guard let facts else {
                completion(Fetcher.unexpectedResponseError, nil)
                return
            }
            cache.didYouKnowItems = facts
            sharedCache.saveCache(cache)
            try? self.userDefaultsStore?.save(key: key, value: stringToday)
            completion(nil, facts)
        }
    }

    private func cachedFileName(for siteURL: URL) -> String {
        let host = siteURL.host ?? ""

        let fileNamePrefix: String
        if let languageVariantCode = siteURL.wmf_languageVariantCode {
            fileNamePrefix = "\(host)-\(languageVariantCode)"
        } else {
            fileNamePrefix = host
        }

        let unencodedFileName = "\(fileNamePrefix)"
        return unencodedFileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? unencodedFileName
    }

}
