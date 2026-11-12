import Foundation

// @unchecked Sendable: must stay an NSObject subclass for Obj-C callers, so it
// cannot be an actor. All mutable state lives in WMFLockIsolated boxes below.
@objc public final class WMFTempAccountDataController: NSObject, @unchecked Sendable {
    @objc public static let shared = WMFTempAccountDataController()

    private let _mediaWikiService = WMFLockIsolated(WMFDataEnvironment.current.mediaWikiService)
    private var mediaWikiService: WMFService? {
        get { _mediaWikiService.value }
        set { _mediaWikiService.value = newValue }
    }

    private let _primaryWikiHasTempAccountsEnabledBox = WMFLockIsolated<Bool?>(nil)
    private var _primaryWikiHasTempAccountsEnabled: Bool? {
        get { _primaryWikiHasTempAccountsEnabledBox.value }
        set { _primaryWikiHasTempAccountsEnabledBox.value = newValue }
    }
    @objc public var primaryWikiHasTempAccountsEnabled: Bool {
        return _primaryWikiHasTempAccountsEnabled ?? false
    }

    private let _wikisWithTempAccountsEnabled = WMFLockIsolated<[String]>([])
    public var wikisWithTempAccountsEnabled: [String] {
        get { _wikisWithTempAccountsEnabled.value }
        set { _wikisWithTempAccountsEnabled.value = newValue }
    }

    @objc public func checkWikiTempAccountAvailability(language: String, isCheckingPrimaryWiki: Bool) {
        Task {
            await asyncCheckWikiTempAccountAvailability(language: language, isCheckingPrimaryWiki: isCheckingPrimaryWiki)
        }
    }

    @discardableResult
    public func asyncCheckWikiTempAccountAvailability(language: String, isCheckingPrimaryWiki: Bool) async -> Bool {
        if wikisWithTempAccountsEnabled.contains(language) {
            if isCheckingPrimaryWiki {
                _primaryWikiHasTempAccountsEnabled = true
            }
            return true
        }

        do {
            let hasTempStatus = try await getTempAccountStatusForWiki(language: language)

            if hasTempStatus, !wikisWithTempAccountsEnabled.contains(language) {
                wikisWithTempAccountsEnabled.append(language)
            }

            if isCheckingPrimaryWiki {
                _primaryWikiHasTempAccountsEnabled = hasTempStatus
            }

            return hasTempStatus
        } catch {
            debugPrint("Error fetching temporary account status: \(error)")
            return false
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

    private func fetchWikiTempStatus(project: WMFProject, completion: (@Sendable (Result<Bool, Error>) -> Void)? = nil) {
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

    @_spi(Testing) public func reset() {
        mediaWikiService = WMFDataEnvironment.current.mediaWikiService
        _primaryWikiHasTempAccountsEnabled = nil
        wikisWithTempAccountsEnabled = []
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
