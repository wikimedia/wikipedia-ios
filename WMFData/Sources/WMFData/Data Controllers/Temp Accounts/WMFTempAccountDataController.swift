import Foundation

@objc public class WMFTempAccountDataController: NSObject {

    private var mediaWikiService = WMFDataEnvironment.current.mediaWikiService
    @objc public static let shared = WMFTempAccountDataController()

    // todo - save to user defaults
    private(set) public var primaryWikiHasTempAccountsEnabled: Bool?
    private(set) public var wikisWithTempAccountsEnabled: [String] = []

    @objc public func checkWikiTempAccountAvailability(language: String, isCheckingPrimaryWiki: Bool) {
        if !wikisWithTempAccountsEnabled.contains(language) {
            Task {
                do {
                    let tempStatus = try await getTempAccountStatusForWiki(language: language)
                    if isCheckingPrimaryWiki {
                        self.primaryWikiHasTempAccountsEnabled = tempStatus
                    }
                    wikisWithTempAccountsEnabled.append(language)
                } catch {
                    print("Error fetching temporary account status: \(error)")
                }
            }
        }
    }

    private func getTempAccountStatusForWiki(language: String) async throws -> Bool {
        let wmfLanguage = WMFLanguage(languageCode: language, languageVariantCode: nil)
        let project = WMFProject.wikipedia(wmfLanguage)

        return try await withCheckedThrowingContinuation { continuation in
            fetchWikiTempStatus(project: project) { status in
                switch status {
                case .success(let isTemporary):
                    continuation.resume(returning: isTemporary)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func fetchWikiTempStatus(project: WMFProject, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        guard let mediaWikiService else {
            completion?(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            completion?(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        let parameters: [String: Any] = [
            "action": "query",
            "format": "json",
            "meta": "siteinfo",
            "formatversion": "2",
            "siprop": "autocreatetempuser"
        ]

        let request = WMFMediaWikiServiceRequest(url:url, method: .GET, backend: .mediaWiki, parameters: parameters)

        mediaWikiService.performDecodableGET(request: request) { (result: Result<TempStatusResponse, Error>) in
            switch result {
            case .success(let response):
                completion?(.success(response.query.autocreatetempuser.enabled))
            case .failure(let error):
                completion?(.failure(error))

            }
        }
    }
}

private struct TempStatusResponse: Codable {
    let batchcomplete: Bool
    let query: TempStatusQuery
}

private struct TempStatusQuery: Codable {
    let autocreatetempuser: AutoCreateTempUser
}

private struct AutoCreateTempUser: Codable {
    let enabled: Bool
}
