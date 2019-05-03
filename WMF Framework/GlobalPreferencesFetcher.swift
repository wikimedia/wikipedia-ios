import Foundation

class GlobalPreferencesFetcher: Fetcher {
    private let siteURL: URL

    required init(session: Session, configuration: Configuration) {
        siteURL = configuration.mediaWikiAPIURLComponentsBuilder().components().url!
        super.init(session: session, configuration: configuration)
    }

    func set(optionName: String, to optionValue: String?, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard session.isAuthenticated else {
            completion(.failure(RequestError.notAuthorized))
            return
        }
        var parameters = [
            "action": "globalpreferences",
            "format": "json",
            "formatversion": "2",
            "optionname": optionName,
        ]
        if let value = optionValue {
            parameters["optionvalue"] = value
        }
        performTokenizedMediaWikiAPIPOST(to: siteURL, with: parameters) { (result, response, error) in
            guard
                let status = result?["globalpreferences"] as? String,
                status == "success"
            else {
                completion(.failure(error ?? Fetcher.unexpectedResponseError))
                return
            }
            completion(.success(true))
        }
    }
    
    func get(_ completion: @escaping(Result<[String: Any], Error>) -> Void) {
        guard session.isAuthenticated else {
            completion(.success([:]))
            return
        }
        let parameters = [
            "action": "query",
            "format": "json",
            "formatversion": "2",
            "meta": "globalpreferences"
        ]
        performMediaWikiAPIGET(for: siteURL, with: parameters) { (result, response, error) in
            guard let result = result else {
                completion(.failure(error ?? RequestError.unexpectedResponse))
                return
            }
            guard
                let query = result["query"] as? [String: Any],
                let globalpreferences = query["globalpreferences"] as? [String: Any],
                let preferences = globalpreferences["preferences"] as? [String: Any]
            else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            
            completion(.success(preferences))
        }
    }
}
