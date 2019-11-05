
enum DiffThankerError: LocalizedError {
    case thanksStatusNotSuccess
    case thanksError(String)

    var errorDescription: String? {
        switch self {
        case .thanksStatusNotSuccess:
            return "Thanks did not succeed"
        case .thanksError(let message):
            return message
        }
    }
}

struct DiffThankerResult {
    var recipient: String
    init(recipient:String) {
        self.recipient = recipient
    }
}

class DiffThanker: Fetcher {
    func thank(siteURL: URL, rev: Int, completion: @escaping ((Result<DiffThankerResult, Error>) -> Void)) {
        let parameters = [
            "action": "thank",
            "rev": String(rev),
            "source": "diff",
            "errorsuselocal": "1",
            "format": "json"
        ];
        performTokenizedMediaWikiAPIPOST(to: siteURL, with: parameters) { (result, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let error = result?["error"] as? [String: Any], let info = error["info"] as? String {
                completion(.failure(DiffThankerError.thanksError(info)))
                return
            }
            guard
                let resultDict = result?["result"] as? [String: Any],
                let successInt = resultDict["success"] as? Int,
                successInt == 1,
                let recipient = resultDict["recipient"] as? String
                else {
                    completion(.failure(DiffThankerError.thanksStatusNotSuccess))
                    return
            }
            completion(.success(DiffThankerResult.init(recipient: recipient)))
        }
    }
}
