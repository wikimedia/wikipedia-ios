import Foundation

@objc(WMFRelatedSearchFetcher)
final class RelatedSearchFetcher: Fetcher {
    @objc static let MaxResultLimit = 20

    private struct RelatedPages: Decodable {
        let pages: [Page]?
        struct Page: Decodable {
            let id: Int?
            let revision: String?
            let index: Int?
            let namespace: Int?
            let title: String?
            let displayTitle: String?
            let description: String?
            let extract: String?
            let thumbnail: Image?
            let coordinates: Coordinates?

            var isList: Bool {
                return description?.contains("Wikimedia list article") ?? false
            }

            var isDisambiguation: Bool {
                return description?.contains("disambiguation page") ?? false
            }

            enum CodingKeys: String, CodingKey {
                case id = "pageid"
                case revision
                case index
                case namespace = "ns"
                case title
                case displayTitle = "displaytitle"
                case description
                case extract
                case thumbnail
                case coordinates
            }

            struct Image: Decodable {
                let source: String?

                var url: URL? {
                    guard let source = source else {
                        return nil
                    }
                    return URL(string: source)
                }
            }

            struct Coordinates: Decodable {
                let lat: Double
                let lon: Double
            }
        }
    }

    @objc func fetchRelatedArticles(forArticleWithURL articleURL: URL?, resultLimit: Int = RelatedSearchFetcher.MaxResultLimit, completion: @escaping (Error?, [MWKSearchResult]?) -> Void) {
        guard
            let articleURL = articleURL,
            let articleTitle = articleURL.wmf_titleWithUnderscores
        else {
            completion(Fetcher.invalidParametersError, nil)
            return
        }

        var resultLimit = resultLimit
        if resultLimit > RelatedSearchFetcher.MaxResultLimit {
            DDLogError("Illegal attempt to request \(resultLimit) articles, limiting to \(RelatedSearchFetcher.MaxResultLimit).")
            resultLimit = RelatedSearchFetcher.MaxResultLimit
        }

        let pathComponents = ["page", "related", articleTitle]
        guard let taskURL = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(articleURL.host, appending: pathComponents).url else {
            completion(Fetcher.invalidParametersError, nil)
            return
        }
        
        session.jsonDecodableTask(with: taskURL) { (relatedPages: RelatedPages?, response, error) in
            if let error = error {
                completion(error, nil)
                return
            }

            guard
                let response = response,
                let httpResponse = response as? HTTPURLResponse
            else {
                completion(Fetcher.unexpectedResponseError, nil)
                return
            }

            guard httpResponse.statusCode == 200 else {
                let error = httpResponse.statusCode == 302 ? Fetcher.noNewDataError : Fetcher.unexpectedResponseError
                completion(error, nil)
                return
            }

            guard
                let pages = relatedPages?.pages,
                !pages.isEmpty
            else {
                completion(nil, nil)
                return
            }

            let results: [MWKSearchResult] = pages.compactMap { page in
                guard
                    let id = page.id,
                    let revisionString = page.revision,
                    let revision = Int(revisionString)
                else {
                    return nil
                }
                let index = page.index.flatMap { NSNumber(value: $0) }
                let namespace = page.namespace.flatMap { NSNumber(value: $0) }
                let location = page.coordinates.flatMap { CLLocation(latitude: $0.lat, longitude: $0.lon) }
                return MWKSearchResult(articleID: id, revID: revision, title: page.title, displayTitle: page.displayTitle, displayTitleHTML: page.displayTitle, wikidataDescription: page.description, extract: page.extract, thumbnailURL: page.thumbnail?.url, index: index, isDisambiguation: page.isDisambiguation, isList: page.isList, titleNamespace: namespace, location: location)
            }

            completion(nil, results)
        }
    }
}
