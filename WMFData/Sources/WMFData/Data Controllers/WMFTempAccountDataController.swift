import Foundation

@objc public class WMFTempAccountDataController: NSObject {

    private var mediaWikiService = WMFDataEnvironment.current.mediaWikiService
    @objc public static let shared = WMFTempAccountDataController()

    private var primaryWikiTempStatus: Bool?
    private var lastPrimaryLanguage: String?

    @objc public func primaryWikiIsTemp(language: String) {
        self.lastPrimaryLanguage = language
        primaryWikiTempStatus = getTempAccountStatutsForWiki(language: language)
    }

    public func getTempAccountStatutsForWiki(language: String) -> Bool {
        let wmfLanguage = WMFLanguage(languageCode: language, languageVariantCode: nil)
        let project = WMFProject.wikipedia(wmfLanguage)

        var isTemp = false
        fetchWikiTempStatus(project: project) { status in
            switch status {
            case .success(let isTemporary):
                isTemp = isTemporary
            case .failure:
                break
            }
        }
        return isTemp
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
