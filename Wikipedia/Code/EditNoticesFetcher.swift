class EditNoticesFetcher: Fetcher {

    // MARK: - Nested Types

    struct Notice: Codable {
        let name: String
        let description: String
    }

    private struct Response: Codable {
        struct VisualEditor: Codable {
            let notices: [String: String]?
        }

        enum CodingKeys: String, CodingKey {
            case visualEditor = "visualeditor"
        }

        let visualEditor: VisualEditor?
    }

    // MARK: - Public

    func fetchNotices(for articleURL: URL, completion: @escaping (Result<[Notice], Error>) -> Void) {
        guard let title = articleURL.wmf_title else {
            completion(.failure(RequestError.invalidParameters))
            return
        }

        let parameters: [String: Any] = [
            "action": "visualeditor",
            "paction": "metadata",
            "page": title,
            "errorsuselocal": "1",
            "formatversion" : "2",
            "format": "json"
        ]

        performDecodableMediaWikiAPIGET(for: articleURL, with: parameters) { (result: Result<Response, Error>) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                var notices: [Notice] = []
                if let rawNotices = response.visualEditor?.notices?.filter({ $0.key.contains("editnotice")}) {
                    for rawNotice in rawNotices {
                        notices.append(Notice(name: rawNotice.key, description: rawNotice.value))
                    }
                }

                completion(.success(notices))
            }
        }
    }

}
