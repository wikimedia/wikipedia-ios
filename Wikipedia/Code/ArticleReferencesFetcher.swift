class ArticleReferencesFetcher: Fetcher {
    
    func fetchReferences(for articleURL: URL, completion: @escaping (Result<References, Error>) -> Void) {
        guard let title = articleURL.percentEncodedPageTitleForPathComponents else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        let components = ["page", "references", title]
        performMobileAppsServicesGET(for: articleURL, pathComponents: components) { (references: References?, response, error) in
            guard let references = references else {
                completion(.failure(error ?? RequestError.unexpectedResponse))
                return
            }
            completion(.success(references))
        }
    }
}
